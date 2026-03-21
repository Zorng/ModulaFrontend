import 'package:equatable/equatable.dart';

enum InventoryJournalDatePreset { today, yesterday, last7Days, custom }

class InventoryJournalDateFilter extends Equatable {
  const InventoryJournalDateFilter({
    required this.preset,
    this.date,
    this.from,
    this.to,
  });

  final InventoryJournalDatePreset preset;
  final DateTime? date;
  final DateTime? from;
  final DateTime? to;

  @override
  List<Object?> get props => [preset, date, from, to];
}

InventoryJournalDateFilter resolveInventoryJournalDateFilter(
  InventoryJournalDateFilter filter, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  return switch (filter.preset) {
    InventoryJournalDatePreset.today => InventoryJournalDateFilter(
      preset: InventoryJournalDatePreset.today,
      date: inventoryJournalDateOnly(filter.date ?? current),
    ),
    InventoryJournalDatePreset.yesterday => InventoryJournalDateFilter(
      preset: InventoryJournalDatePreset.yesterday,
      date: inventoryJournalDateOnly(
        filter.date ?? current.subtract(const Duration(days: 1)),
      ),
    ),
    InventoryJournalDatePreset.last7Days => InventoryJournalDateFilter(
      preset: InventoryJournalDatePreset.last7Days,
      from: inventoryJournalDateOnly(
        filter.from ?? current.subtract(const Duration(days: 6)),
      ),
      to: inventoryJournalDateOnly(filter.to ?? current),
    ),
    InventoryJournalDatePreset.custom => InventoryJournalDateFilter(
      preset: InventoryJournalDatePreset.custom,
      from: inventoryJournalDateOnly(filter.from ?? current),
      to: inventoryJournalDateOnly(filter.to ?? current),
    ),
  };
}

DateTime inventoryJournalDateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String formatInventoryJournalQueryDate(DateTime value) {
  final date = inventoryJournalDateOnly(value);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
