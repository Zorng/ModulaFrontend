import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/branch/data/dto/branch_dto.dart';
import 'package:modular_pos/features/branch/data/branch_mapper.dart';

void main() {
  group('Branch DTO and Mapping', () {
    test('BranchDto.fromJson parses valid payload correctly', () {
      final json = {
        'id': 'branch-123',
        'tenant_id': 'tenant-456',
        'name': 'Downtown Branch',
        'status': 'ACTIVE',
        'address': '123 Main St',
        'contact_phone': '+1234567890',
        'contact_email': 'downtown@example.com',
        'created_at': '2024-01-15T10:30:00Z',
        'updated_at': '2024-01-20T14:45:00Z',
      };

      final dto = BranchDto.fromJson(json);

      expect(dto.id, equals('branch-123'));
      expect(dto.tenantId, equals('tenant-456'));
      expect(dto.name, equals('Downtown Branch'));
      expect(dto.status, equals('ACTIVE'));
      expect(dto.address, equals('123 Main St'));
      expect(dto.contactPhone, equals('+1234567890'));
      expect(dto.contactEmail, equals('downtown@example.com'));
      expect(dto.createdAt, equals('2024-01-15T10:30:00Z'));
      expect(dto.updatedAt, equals('2024-01-20T14:45:00Z'));
    });

    test('BranchDto.fromJson handles null optional fields', () {
      final json = {
        'id': 'branch-123',
        'tenant_id': 'tenant-456',
        'name': 'Minimal Branch',
        'status': 'FROZEN',
        'created_at': '2024-01-15T10:30:00Z',
      };

      final dto = BranchDto.fromJson(json);

      expect(dto.id, equals('branch-123'));
      expect(dto.name, equals('Minimal Branch'));
      expect(dto.status, equals('FROZEN'));
      expect(dto.address, isNull);
      expect(dto.contactPhone, isNull);
      expect(dto.contactEmail, isNull);
      expect(dto.updatedAt, isNull);
    });

    test('BranchMapper.toDomain maps DTO to domain model correctly', () {
      final dto = BranchDto(
        id: 'branch-123',
        tenantId: 'tenant-456',
        name: 'Test Branch',
        status: 'ACTIVE',
        address: '456 Oak Ave',
        contactPhone: '+9876543210',
        contactEmail: 'test@branch.com',
        createdAt: '2024-01-15T10:30:00Z',
        updatedAt: '2024-01-20T14:45:00Z',
      );

      final branch = BranchMapper.toDomain(dto);

      expect(branch.id, equals('branch-123'));
      expect(branch.tenantId, equals('tenant-456'));
      expect(branch.name, equals('Test Branch'));
      expect(branch.status, equals('ACTIVE'));
      expect(branch.isActive, isTrue);
      expect(branch.isFrozen, isFalse);
      expect(branch.address, equals('456 Oak Ave'));
      expect(branch.contactPhone, equals('+9876543210'));
      expect(branch.contactEmail, equals('test@branch.com'));
      expect(branch.createdAt, isA<DateTime>());
      expect(branch.updatedAt, isA<DateTime>());
    });

    test('BranchMapper.toDomainList maps list of DTOs', () {
      final dtos = [
        BranchDto(
          id: 'branch-1',
          tenantId: 'tenant-1',
          name: 'Branch One',
          status: 'ACTIVE',
          createdAt: '2024-01-15T10:30:00Z',
        ),
        BranchDto(
          id: 'branch-2',
          tenantId: 'tenant-1',
          name: 'Branch Two',
          status: 'FROZEN',
          createdAt: '2024-01-16T10:30:00Z',
        ),
      ];

      final branches = BranchMapper.toDomainList(dtos);

      expect(branches.length, equals(2));
      expect(branches[0].id, equals('branch-1'));
      expect(branches[0].isActive, isTrue);
      expect(branches[1].id, equals('branch-2'));
      expect(branches[1].isFrozen, isTrue);
    });

    test('Branch domain model status helpers work correctly', () {
      final activeBranch = BranchMapper.toDomain(
        BranchDto(
          id: 'b1',
          tenantId: 't1',
          name: 'Active',
          status: 'ACTIVE',
          createdAt: '2024-01-15T10:30:00Z',
        ),
      );

      final frozenBranch = BranchMapper.toDomain(
        BranchDto(
          id: 'b2',
          tenantId: 't1',
          name: 'Frozen',
          status: 'FROZEN',
          createdAt: '2024-01-15T10:30:00Z',
        ),
      );

      expect(activeBranch.isActive, isTrue);
      expect(activeBranch.isFrozen, isFalse);
      expect(frozenBranch.isActive, isFalse);
      expect(frozenBranch.isFrozen, isTrue);
    });

    test('Branch copyWith creates modified copy', () {
      final original = BranchMapper.toDomain(
        BranchDto(
          id: 'b1',
          tenantId: 't1',
          name: 'Original',
          status: 'ACTIVE',
          createdAt: '2024-01-15T10:30:00Z',
        ),
      );

      final modified = original.copyWith(
        name: 'Modified',
        status: 'FROZEN',
      );

      expect(modified.id, equals(original.id));
      expect(modified.tenantId, equals(original.tenantId));
      expect(modified.name, equals('Modified'));
      expect(modified.status, equals('FROZEN'));
      expect(modified.createdAt, equals(original.createdAt));
    });
  });
}
