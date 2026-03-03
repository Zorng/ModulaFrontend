import 'package:modular_pos/core/network/api_contract.dart';

import '../test_utils/fixture_reader.dart';

Map<String, dynamic> readInventoryEnvelopeFixture(String fixtureFileName) {
  return readJsonMapFixture(fixturePath('inventory/$fixtureFileName'));
}

List<Map<String, dynamic>> readInventoryDataListFixture(
  String fixtureFileName,
) {
  final envelope = readInventoryEnvelopeFixture(fixtureFileName);
  final rawData = ApiContract.unwrapData(envelope);
  if (rawData is List) {
    return rawData
        .whereType<Map>()
        .map((row) => ApiContract.asJsonMap(row))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}
