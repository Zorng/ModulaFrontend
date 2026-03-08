import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_repository_contract.dart';

void main() {
  group('Attendance payload mapping', () {
    test('check-in payload uses v0 occurredAt + location shape', () {
      const payload = AttendanceCheckInPayload(
        branchId: 'branch-1',
        clientOpId: 'intent-1',
        clientTs: '2026-03-08T08:00:00.000Z',
        deviceLat: 11.5564,
        deviceLng: 104.9282,
        deviceAccuracyM: 12.5,
      );

      expect(payload.toJson(), {
        'occurredAt': '2026-03-08T08:00:00.000Z',
        'location': {
          'latitude': 11.5564,
          'longitude': 104.9282,
          'accuracyMeters': 12.5,
          'capturedAt': '2026-03-08T08:00:00.000Z',
        },
      });
    });

    test('check-out payload omits location when GPS is unavailable', () {
      const payload = AttendanceCheckOutPayload(
        branchId: 'branch-1',
        clientOpId: 'intent-2',
        clientTs: '2026-03-08T17:00:00.000Z',
      );

      expect(payload.toJson(), {'occurredAt': '2026-03-08T17:00:00.000Z'});
    });
  });
}
