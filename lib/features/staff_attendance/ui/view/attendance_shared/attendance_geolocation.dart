import 'package:geolocator/geolocator.dart';

class AttendanceGeoSnapshot {
  const AttendanceGeoSnapshot({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
  });

  const AttendanceGeoSnapshot.empty()
    : latitude = null,
      longitude = null,
      accuracyM = null;

  final double? latitude;
  final double? longitude;
  final double? accuracyM;
}

class AttendanceGeolocation {
  const AttendanceGeolocation._();

  static Future<AttendanceGeoSnapshot> capture() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return const AttendanceGeoSnapshot.empty();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const AttendanceGeoSnapshot.empty();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      return AttendanceGeoSnapshot(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyM: position.accuracy,
      );
    } catch (_) {
      return const AttendanceGeoSnapshot.empty();
    }
  }
}
