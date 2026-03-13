import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/branchV2/data/branch_mapper.dart';
import 'package:modular_pos/features/branchV2/data/dto/branch_dto.dart';

void main() {
  test('BranchAccessibleBranchDto parses canonical profile fields', () {
    final dto = BranchAccessibleBranchDto.fromJson({
      'branchId': 'branch-1',
      'tenantId': 'tenant-1',
      'branchName': 'Olympic',
      'branchAddress': 'Street 2004',
      'contactNumber': '+85512000009',
      'khqrReceiverAccountId': 'khqr-1',
      'khqrReceiverName': 'Main Receiver',
      'attendanceLocationVerificationMode': 'checkin_only',
      'workplaceLocation': {
        'latitude': 11.5564,
        'longitude': 104.9282,
        'radiusMeters': 100,
      },
      'status': 'ACTIVE',
    });

    expect(dto.attendanceLocationVerificationMode, 'checkin_only');
    expect(dto.workplaceLocation, isNotNull);
    expect(dto.workplaceLocation!.latitude, 11.5564);
    expect(dto.workplaceLocation!.longitude, 104.9282);
    expect(dto.workplaceLocation!.radiusMeters, 100.0);

    final json = dto.toJson();
    expect(json['attendanceLocationVerificationMode'], 'checkin_only');
    expect(json['workplaceLocation'], isA<Map<String, dynamic>>());
  });

  test('BranchAccessibleBranchDto accepts alias key as fallback input', () {
    final dto = BranchAccessibleBranchDto.fromJson({
      'branchId': 'branch-1',
      'tenantId': 'tenant-1',
      'branchName': 'Olympic',
      'attendanceLocationVerification': 'checkin-and-checkout',
      'workplaceLocation': null,
      'status': 'ACTIVE',
    });

    expect(dto.attendanceLocationVerificationMode, 'checkin-and-checkout');
    expect(dto.workplaceLocation, isNull);
  });

  test('BranchMapper normalizes mode and maps workplace location', () {
    final dto = BranchAccessibleBranchDto.fromJson({
      'branchId': 'branch-2',
      'tenantId': 'tenant-1',
      'branchName': 'Tuol Kork',
      'attendanceLocationVerificationMode': 'checkin and checkout',
      'workplaceLocation': {
        'latitude': '11.6000',
        'longitude': '104.9000',
        'radiusMeters': '150',
      },
      'status': 'ACTIVE',
    });

    final item = BranchMapper.toBranchListItem(dto);
    expect(item.attendanceLocationVerificationMode, 'checkin_and_checkout');
    expect(item.workplaceLocation, isNotNull);
    expect(item.workplaceLocation!.latitude, 11.6);
    expect(item.workplaceLocation!.longitude, 104.9);
    expect(item.workplaceLocation!.radiusMeters, 150.0);
  });

  test('BranchAccessibleBranchDto drops invalid workplace location payload', () {
    final dto = BranchAccessibleBranchDto.fromJson({
      'branchId': 'branch-3',
      'tenantId': 'tenant-1',
      'branchName': 'BKK',
      'attendanceLocationVerificationMode': 'disabled',
      'workplaceLocation': {
        'latitude': 11.5,
        'longitude': 104.9,
      },
      'status': 'ACTIVE',
    });

    final item = BranchMapper.toBranchListItem(dto);
    expect(dto.workplaceLocation, isNull);
    expect(item.workplaceLocation, isNull);
    expect(item.attendanceLocationVerificationMode, 'disabled');
  });
}
