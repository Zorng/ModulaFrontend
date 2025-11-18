import 'package:flutter/material.dart';
import 'package:modular_pos/core/widgets/portal_action.dart';

class PortalShell extends StatefulWidget {
  const PortalShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actions,
    this.initialActionId,
    this.userName,
    this.userRole,
    this.userInitial,
    this.onSettingsTap,
  });

  final String title;
  final String subtitle;
  final List<PortalAction> actions;
  final String? initialActionId;
  final String? userName;
  final String? userRole;
  final String? userInitial;
  final VoidCallback? onSettingsTap;

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
    final isWide = MediaQuery.of(context).size.width >= 900;
    final action = widget.actions[_selectedIndex];

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
              CircleAvatar(
                radius: 18,
                child: Text(
                  widget.userInitial ??
                      (widget.userName?.characters.first.toUpperCase() ?? '?'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.userName ?? widget.title),
                  Text(
                    widget.userRole ?? widget.subtitle,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
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
          if (isWide)
            SizedBox(
              width: 260,
              child: Material(
                elevation: 1,
                child: ListView.separated(
                  itemCount: widget.actions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = widget.actions[index];
                    final selected = index == _selectedIndex;
                    return ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      selected: selected,
                      onTap: () => setState(() => _selectedIndex = index),
                    );
                  },
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 12),
                Builder(builder: action.builder),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
