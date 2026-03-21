import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The result returned by [showLocationPickerDialog].
/// Both [latLng] and [radiusMeters] are ready to be persisted to the database.
class LocationPickerResult {
  const LocationPickerResult({required this.latLng, required this.radiusMeters});

  final LatLng latLng;

  /// Geofence / service-area radius in metres.
  final double radiusMeters;
}

/// Opens a full-screen-ish dialog where the user taps the map to pin a
/// location and optionally adjusts a radius circle.
/// Returns a [LocationPickerResult] with the confirmed [LatLng] and radius,
/// or `null` if the user cancelled.
///
/// Pass either [initialLocation] or raw [latitude] + [longitude] doubles
/// (e.g. values loaded from the database) to pre-populate the map with a
/// saved location. If both are provided, [initialLocation] takes precedence.
///
/// Pass [initialRadius] (or raw [radiusMeters]) to restore a previously saved
/// radius. Defaults to 200 m when no value is supplied.
Future<LocationPickerResult?> showLocationPickerDialog({
  required BuildContext context,
  LatLng? initialLocation,
  double? latitude,
  double? longitude,
  double? initialRadius,
  double? radiusMeters,
}) {
  final resolvedLocation =
      initialLocation ??
      (latitude != null && longitude != null
          ? LatLng(latitude, longitude)
          : null);
  final resolvedRadius = initialRadius ?? radiusMeters ?? 200.0;

  return showDialog<LocationPickerResult>(
    context: context,
    builder: (_) => _LocationPickerDialog(
      initialLocation: resolvedLocation,
      initialRadius: resolvedRadius,
    ),
  );
}

class _LocationPickerDialog extends StatefulWidget {
  const _LocationPickerDialog({this.initialLocation, required this.initialRadius});
  final LatLng? initialLocation;
  final double initialRadius;

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  // Default to Phnom Penh when no initial location is given.
  static const _defaultTarget = LatLng(11.5564, 104.9282);
  static const _minRadius = 10.0;
  static const _maxRadius = 500.0;

  GoogleMapController? _mapController;
  LatLng? _picked;
  double _radius = 200;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialLocation;
    _radius = widget.initialRadius.clamp(_minRadius, _maxRadius);
  }

  LatLng get _cameraTarget => widget.initialLocation ?? _defaultTarget;

  Set<Circle> get _circles {
    final picked = _picked;
    if (picked == null) return {};
    return {
      Circle(
        circleId: const CircleId('radius'),
        center: picked,
        radius: _radius,
        fillColor: Colors.blue.withValues(alpha: 0.15),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    };
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _picked = latLng);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 16),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pick Workplace Location',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tap on the map to pin the location, or use the button to jump to your current position.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 8),

            // ── Map ───────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _cameraTarget,
                      zoom: picked != null ? 15 : 13,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: (latLng) => setState(() => _picked = latLng),
                    markers: picked == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('workplace'),
                              position: picked,
                              draggable: true,
                              onDragEnd: (latLng) =>
                                  setState(() => _picked = latLng),
                            ),
                          },
                    circles: _circles,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),

                  // My location FAB
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FloatingActionButton.small(
                      heroTag: 'location_picker_my_location',
                      tooltip: 'Use my current location',
                      onPressed: _locating ? null : _goToMyLocation,
                      child: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),

            // ── Coordinate preview ────────────────────────────────────────
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                picked == null
                    ? 'No location selected — tap the map to pin one'
                    : 'Lat ${picked.latitude.toStringAsFixed(6)},  '
                          'Lng ${picked.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: picked == null ? Colors.black45 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // ── Radius slider ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.radar, size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    'Radius',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _radius,
                      min: _minRadius,
                      max: _maxRadius,
                      divisions: 99,
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '${_radius.round()} m',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: picked == null
                          ? null
                          : () => Navigator.of(context).pop(
                                LocationPickerResult(
                                  latLng: picked,
                                  radiusMeters: _radius,
                                ),
                              ),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
