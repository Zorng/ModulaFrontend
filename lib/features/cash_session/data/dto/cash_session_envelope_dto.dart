import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/cash_session/data/dto/cash_session_dto.dart';

class CashSessionEnvelopeDto {
  const CashSessionEnvelopeDto({required this.session});

  final CashSessionDto? session;

  factory CashSessionEnvelopeDto.fromJson(Map<String, dynamic> json) {
    final session = json['session'];
    if (session == null) {
      return const CashSessionEnvelopeDto(session: null);
    }
    final sessionMap = ApiContract.asJsonMap(session);
    if (sessionMap.isEmpty) {
      return const CashSessionEnvelopeDto(session: null);
    }
    return CashSessionEnvelopeDto(session: CashSessionDto.fromJson(sessionMap));
  }
}
