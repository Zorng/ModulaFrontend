import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/navigation/portal_action.dart';
import 'package:modular_pos/core/widgets/navigation/tenant_profile_header.dart';

class PortalShell extends StatefulWidget {
  const PortalShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.initialActionId,
    this.tenantName,
    this.branchName,
    this.tenantInitial,
    this.onSettingsTap,
    this.onProfileTap,
  });

  final String title;
  final String subtitle;
  final List<PortalAction> actions;
  final String? initialActionId;
  final String? tenantName;
  final String? branchName;
  final String? tenantInitial;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onProfileTap;

  @override
  State<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends State<PortalShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _initialIndex();
  }

  int _initialIndex() {
    if (widget.initialActionId == null) return 0;
    final idx = widget.actions.indexWhere(
      (a) => a.id == widget.initialActionId,
    );
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.actions[_selectedIndex];
    final content = action.builder(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 4,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              TenantProfileHeader(
                tenantName: widget.tenantName ?? widget.title,
                branchName: widget.branchName ?? widget.subtitle,
                initial:
                    widget.tenantInitial ??
                    (widget.tenantName?.characters.first.toUpperCase() ?? '?'),
                onBackPressed: () => context.go(AppRoute.branchSelection.path),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onSettingsTap,
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: content is Scaffold
                ? content
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 12),
                      content,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
