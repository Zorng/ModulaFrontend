import 'dart:math' as math;

import 'package:equatable/equatable.dart';

class InventoryPaginatedResult<T> extends Equatable {
  const InventoryPaginatedResult({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
  });

  final List<T> items;
  final int limit;
  final int offset;
  final int total;
  final bool hasMore;

  int get safeLimit => limit <= 0 ? 1 : limit;

  int get safeOffset => offset < 0 ? 0 : offset;

  int get currentPage => (safeOffset ~/ safeLimit) + 1;

  int get totalPages => total <= 0 ? 0 : ((total - 1) ~/ safeLimit) + 1;

  bool get hasPreviousPage => safeOffset > 0;

  int get visibleRangeStart => items.isEmpty ? 0 : safeOffset + 1;

  int get visibleRangeEnd {
    if (items.isEmpty) return 0;
    final end = safeOffset + items.length;
    if (total <= 0) return end;
    return math.min(end, total);
  }

  InventoryPaginatedResult<T> copyWith({
    List<T>? items,
    int? limit,
    int? offset,
    int? total,
    bool? hasMore,
  }) {
    return InventoryPaginatedResult<T>(
      items: items ?? this.items,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [items, limit, offset, total, hasMore];
}
