import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomCupertinoListTile extends StatelessWidget {
  const CustomCupertinoListTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding =
        const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
  });

  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // To make the whole area tappable
      child: Padding(
        padding: padding,
        child: Row(
          children: <Widget>[
            if (leading != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: leading!,
              ),
            Expanded(child: title),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}
