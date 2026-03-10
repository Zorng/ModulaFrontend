class ThermalPrinterProfile {
  const ThermalPrinterProfile({
    required this.id,
    required this.label,
    required this.paperWidthMm,
    required this.charactersPerLine,
    required this.baudRate,
    required this.feedLinesAfterPrint,
    required this.supportsCut,
  });

  final String id;
  final String label;
  final int paperWidthMm;
  final int charactersPerLine;
  final int baudRate;
  final int feedLinesAfterPrint;
  final bool supportsCut;
}

abstract final class ThermalPrinterProfiles {
  static const bt58358mm = ThermalPrinterProfile(
    id: 'bt_583_58mm',
    label: 'BT-583 58mm',
    paperWidthMm: 58,
    charactersPerLine: 32,
    baudRate: 9600,
    feedLinesAfterPrint: 4,
    supportsCut: false,
  );

  static const all = <ThermalPrinterProfile>[bt58358mm];

  static ThermalPrinterProfile resolve(String? id) {
    for (final profile in all) {
      if (profile.id == id) {
        return profile;
      }
    }
    return bt58358mm;
  }
}
