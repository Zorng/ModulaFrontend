import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Opens a full-screen-ish dialog where the user taps the map to pin a location.
/// Returns the confirmed [LatLng], or `null` if the user cancelled.
Future<LatLng?> showLocationPickerDialog({
  required BuildContext context,
  LatLng? initialLocation,
}) {
  return showDialog<LatLng>(
    context: context,
    builder: (_) => _LocationPickerDialog(initialLocation: initialLocation),
  );
}

class _LocationPickerDialog extends StatefulWidget {
  const _LocationPickerDialog({this.initialLocation});
  final LatLng? initialLocation;

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  // Default to Phnom Penh when no initial location is given.
  static const _defaultTarget = LatLng(11.5564, 104.9282);

  GoogleMapController? _mapController;
  LatLng? _picked;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialLocation;
  }

  LatLng get _cameraTarget => widget.initialLocation ?? _defaultTarget;

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
      insetPadding: const EdgeInsets.all(24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 580),
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

            // ── Actions ───────────────────────────────────────────────────
            // Align breaks the tight-infinite-width chain from Column(stretch),
            // giving Row(min) loose constraints so buttons can size themselves.
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
                          : () => Navigator.of(context).pop(picked),
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
