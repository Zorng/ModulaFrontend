import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/widgets/navigation/branch_workspace_scaffold.dart';

class AttendanceBottomNavShellPage extends StatelessWidget {
  const AttendanceBottomNavShellPage({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _titles = <String>['Attendance', 'History'];

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.access_time_outlined),
      label: 'Attendance',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      label: 'History',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BranchWorkspaceScaffold(
      title: _titles[navigationShell.currentIndex],
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        items: _items,
        type: BottomNavigationBarType.fixed,
        onTap: navigationShell.goBranch,
      ),
    );
  }
}
