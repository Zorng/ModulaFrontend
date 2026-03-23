import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/notification/ui/components/operational_notification_inbox_action.dart';

class AppBottomNavShellScaffold extends StatelessWidget {
  const AppBottomNavShellScaffold({
    super.key,
    required this.navigationShell,
    required this.items,
    required this.titles,
    this.centerTitle = false,
    this.leading,
    this.actions,
    this.onBackPressed,
    this.backIcon,
    this.backTooltip,
  }) : assert(
         titles.length == items.length,
         'titles and items must have the same length',
       );

  final StatefulNavigationShell navigationShell;
  final List<BottomNavigationBarItem> items;
  final List<String> titles;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final IconData? backIcon;
  final String? backTooltip;

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;
    final isWide = AppBreakpoints.isLarge(MediaQuery.of(context).size.width);
    final showBackButton = onBackPressed != null && !isWide;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: centerTitle,
        leading: showBackButton
            ? AppBackButton(
                onPressed: onBackPressed!,
                icon: backIcon,
                tooltip: backTooltip,
              )
            : leading,
        title: Text(titles[index]),
        actions: <Widget>[
          const OperationalNotificationInboxAction(),
          ...(actions ?? const <Widget>[]),
        ],
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        items: items,
        type: BottomNavigationBarType.fixed,
        onTap: navigationShell.goBranch,
      ),
    );
  }
}
