import 'package:flutter/material.dart';

/// Defines an action (tab) inside a [PortalShell].
///
/// Folder: `lib/core/widgets/navigation/`
class PortalAction {
  const PortalAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
    this.onSelected,
  });

  final String id;
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
  final ValueChanged<BuildContext>? onSelected;
}
