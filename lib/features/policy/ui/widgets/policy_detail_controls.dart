import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/core/theme/responsive.dart';

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
      (states) =>
          states.contains(WidgetState.selected) ? colorScheme.primary : null,
    );
    final trackColor = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.selected)
          ? colorScheme.primary.withValues(alpha: 0.3)
          : null,
    );

    return SwitchListTile.adaptive(
      title: Text(title),
      subtitle: helper != null
          ? Text(helper!)
          : (subtitle != null ? Text(subtitle!) : null),
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
    this.subtitle,
  });

  final String title;
  final String valueText;
  final bool enabled;
  final VoidCallback? onTap;
  final String? hint;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = Theme.of(context).textTheme.bodyMedium?.color;
    final valueColor = enabled
        ? baseColor ?? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.4);

    return ListTile(
      title: Text(title),
      subtitle: subtitle != null
          ? Text(subtitle!)
          : (!enabled && hint != null ? Text(hint!) : null),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: valueColor),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right,
            color: enabled
                ? null
                : colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
      enabled: enabled,
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
    final scheme = Theme.of(context).colorScheme;
    final selected = value == groupValue;
    final textColor = enabled
        ? Theme.of(context).textTheme.bodyLarge?.color ?? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.4);

    return IgnorePointer(
      ignoring: !enabled,
      child: ListTile(
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
        title: Text(title, style: TextStyle(color: textColor)),
        onTap: () => onChanged(value),
      ),
    );
  }
}

class PolicySettingGroup extends StatelessWidget {
  const PolicySettingGroup({super.key, required this.children});

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
    this.breadcrumb = 'Policy',
    this.showEditAction = true,
  });

  final String title;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final Widget child;
  final VoidCallback? onSave;
  final bool canSave;
  final String breadcrumb;
  final bool showEditAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = AppBreakpoints.isLarge(constraints.maxWidth);
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Scaffold(
          appBar: isLarge
              ? null
              : AppBar(
                  automaticallyImplyLeading: false,
                  leading: const AppBackButton(),
                  titleSpacing: 0,
                  centerTitle: false,
                  title: Text(title),
                  actions: showEditAction
                      ? [
                          TextButton(
                            onPressed: onEditToggle,
                            child: Text(isEditing ? 'Cancel' : 'Edit'),
                          ),
                        ]
                      : const [],
                ),
          body: SafeArea(
            child: isLarge
                ? _buildLargeScreenLayout(context, colorScheme, textTheme)
                : _buildSmallScreenLayout(context),
          ),
        );
      },
    );
  }

  Widget _buildSmallScreenLayout(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        child,
        if (isEditing && onSave != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: canSave ? onSave : null,
                child: const Text('Save'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLargeScreenLayout(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header section with white background
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            children: [
              const AppBackButton(),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: textTheme.headlineSmall)),
              if (showEditAction)
                TextButton(
                  onPressed: onEditToggle,
                  child: Text(isEditing ? 'Cancel' : 'Edit'),
                ),
            ],
          ),
        ),
        // Content area - edge to edge
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb
                Text(
                  '$breadcrumb  >  $title',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                child,
                if (isEditing && onSave != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 100,
                              child: TextButton(
                                onPressed: onEditToggle,
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 160,
                              child: FilledButton(
                                onPressed: canSave ? onSave : null,
                                child: const Text('Save Changes'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
