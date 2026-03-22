import 'package:modular_pos/features/reporting/data/dto/reporting_dto_utils.dart';

class ReportScopeDto {
  const ReportScopeDto({
    required this.tenantId,
    required this.branchScope,
    required this.branchId,
    required this.from,
    required this.to,
    required this.timezone,
    required this.frozenBranchIds,
  });

  final String tenantId;
  final String branchScope;
  final String? branchId;
  final String from;
  final String to;
  final String timezone;
  final List<String> frozenBranchIds;

  factory ReportScopeDto.fromJson(Map<String, dynamic> json) {
    return ReportScopeDto(
      tenantId: dtoToString(json['tenantId']),
      branchScope: dtoToString(json['branchScope']),
      branchId: dtoToNullableString(json['branchId']),
      from: dtoToString(json['from']),
      to: dtoToString(json['to']),
      timezone: dtoToString(json['timezone']),
      frozenBranchIds: dtoToStringList(json['frozenBranchIds']),
    );
  }
}
