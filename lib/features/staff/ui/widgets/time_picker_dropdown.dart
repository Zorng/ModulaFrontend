import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimePickerDropdown extends StatefulWidget {
  const TimePickerDropdown({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
    this.isReadOnly = false,
  });

  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final bool isReadOnly;

  @override
  State<TimePickerDropdown> createState() => _TimePickerDropdownState();
}

class _TimePickerDropdownState extends State<TimePickerDropdown> {
  final GlobalKey _key = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _hideOverlay();
      return;
    }

    final RenderBox renderBox =
        _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 5.0),
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 160,
                  width: size.width,
                  color: Colors.white,
                  child: CupertinoDatePicker(
                    initialDateTime: DateTime(
                      2023,
                      1,
                      1,
                      widget.initialTime.hour,
                      widget.initialTime.minute,
                    ),
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    onDateTimeChanged: (DateTime newDateTime) {
                      final newTime = TimeOfDay.fromDateTime(newDateTime);
                      widget.onTimeChanged(newTime);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _key,
        onTap: widget.isReadOnly ? null : _showOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: widget.isReadOnly
                ? const Color(0xFFF5F7FA)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.initialTime.format(context),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.isReadOnly
                      ? Colors.grey.shade700
                      : Colors.black87,
                ),
              ),
              Icon(
                CupertinoIcons.clock,
                color: widget.isReadOnly ? Colors.grey.shade400 : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
