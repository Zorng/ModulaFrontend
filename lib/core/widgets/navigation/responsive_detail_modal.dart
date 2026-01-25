import 'package:flutter/material.dart';
import 'package:modular_pos/core/theme/responsive.dart';

Future<T?> showResponsiveDetailModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final isWide = AppBreakpoints.isLarge(MediaQuery.of(context).size.width);

  if (isWide) {
    return showDialog<T>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
            child: builder(dialogContext),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final height = MediaQuery.of(sheetContext).size.height * 0.92;
      return SizedBox(height: height, child: builder(sheetContext));
    },
  );
}
