import 'package:modular_pos/features/branch/domain/models/branch.dart';
import 'package:modular_pos/features/branch/data/dto/branch_dto.dart';

/// Maps BranchDto to Branch domain model
class BranchMapper {
  static Branch toDomain(BranchDto dto) {
    return Branch(
      id: dto.id,
      tenantId: dto.tenantId,
      name: dto.name,
      status: dto.status,
      address: dto.address,
      contactPhone: dto.contactPhone,
      contactEmail: dto.contactEmail,
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: dto.updatedAt != null ? DateTime.parse(dto.updatedAt!) : null,
    );
  }

  static List<Branch> toDomainList(List<BranchDto> dtos) {
    return dtos.map(toDomain).toList();
  }
}
