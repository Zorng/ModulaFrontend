import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/app_back_button.dart';

class PolicySwitchTile extends StatelessWidget {
  const PolicySwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.enabled,
    this.helper,
    this.subtitle,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final String? helper;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final thumbColor = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.selected)
          ? colorScheme.primary
          : null,
    );
    final trackColor = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.selected)
          ? colorScheme.primary.withValues(alpha: 0.3)
          : null,
    );

    return SwitchListTile.adaptive(
      title: Text(title),
      subtitle: helper != null ? Text(helper!) : (subtitle != null ? Text(subtitle!) : null),
      value: value,
      onChanged: enabled ? onChanged : null,
      controlAffinity: ListTileControlAffinity.trailing,
      thumbColor: thumbColor,
      trackColor: trackColor,
    );
  }
}

class PolicyValueTile extends StatelessWidget {
  const PolicyValueTile({
    super.key,
    required this.title,
    required this.valueText,
    required this.enabled,
    this.onTap,
    this.hint,
  });

  final String title;
  final String valueText;
  final bool enabled;
  final VoidCallback? onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).textTheme.bodyMedium?.color;
    final valueColor = enabled
        ? baseColor ?? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.4);

    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueText,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: valueColor),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right,
            color:
                enabled ? null : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
      enabled: enabled,
      subtitle: !enabled && hint != null ? Text(hint!) : null,
      onTap: enabled ? onTap : null,
    );
  }
}

class PolicyRadioTile<T> extends StatelessWidget {
  const PolicyRadioTile({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final T value;
  final T? groupValue;
  final bool enabled;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(MaterialState.selected)
          ? colorScheme.primary
          : colorScheme.outlineVariant,
    );
    final textColor = enabled
        ? Theme.of(context).textTheme.bodyLarge?.color ?? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.4);

    return IgnorePointer(
      ignoring: !enabled,
      child: RadioListTile<T>(
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        fillColor: fillColor,
      ),
    );
  }
}

class PolicySettingGroup extends StatelessWidget {
  const PolicySettingGroup({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      content.add(children[i]);
      if (i < children.length - 1) {
        content.add(const Divider(height: 1, indent: 16, endIndent: 16));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.7),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: content),
    );
  }
}

class PolicyComingSoonTile extends StatelessWidget {
  const PolicyComingSoonTile({
    super.key,
    required this.title,
    this.subtitle = 'Coming soon',
    this.icon,
  });

  final String title;
  final String subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.lock_outline),
      enabled: false,
    );
  }
}

class PolicyDetailScaffold extends StatelessWidget {
  const PolicyDetailScaffold({
    super.key,
    required this.title,
    required this.isEditing,
    required this.onEditToggle,
    required this.child,
    this.onSave,
    this.canSave = true,
  });

  final String title;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final Widget child;
  final VoidCallback? onSave;
  final bool canSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const AppBackButton(),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(title),
        actions: [
          TextButton(
            onPressed: onEditToggle,
            child: Text(isEditing ? 'Cancel' : 'Edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            child,
            if (isEditing && onSave != null && canSave)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: onSave,
                    child: const Text('Save'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
