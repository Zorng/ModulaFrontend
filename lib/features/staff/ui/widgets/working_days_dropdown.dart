import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WorkingDaysDropdown extends StatefulWidget {
  const WorkingDaysDropdown({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  final Set<String> selectedDays;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<WorkingDaysDropdown> createState() => _WorkingDaysDropdownState();
}

class _WorkingDaysDropdownState extends State<WorkingDaysDropdown> {
  final GlobalKey _dropdownKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final List<String> _allDays = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  late Set<String> _tempSelectedDays;

  @override
  void initState() {
    super.initState();
    _tempSelectedDays = Set.from(widget.selectedDays);
  }

  String _getWorkingDaysText() {
    if (widget.selectedDays.isEmpty) {
      return 'Select Working Days';
    } else if (widget.selectedDays.length == _allDays.length) {
      return 'All day';
    } else {
      return widget.selectedDays.join(', ');
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _hideOverlay();
      return;
    }
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      // Notify parent of changes when overlay is closed
      widget.onChanged(_tempSelectedDays);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
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
                color: Colors.white,
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: size.width,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setMenuState) {
                      final bool allSelected = _tempSelectedDays.length == _allDays.length;
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          children: [
                            CheckboxListTile(
                              title: const Text('All day'),
                              controlAffinity: ListTileControlAffinity.leading,
                              value: allSelected,
                              onChanged: (bool? value) {
                                setMenuState(() {
                                  if (value == true) {
                                    _tempSelectedDays = Set.from(_allDays);
                                  } else {
                                    _tempSelectedDays.clear();
                                  }
                                });
                              },
                            ),
                            const Divider(height: 1),
                            ..._allDays.map((day) {
                              return CheckboxListTile(
                                title: Text(day),
                                contentPadding: const EdgeInsets.only(left: 38),
                                controlAffinity: ListTileControlAffinity.leading,
                                value: _tempSelectedDays.contains(day),
                                onChanged: (bool? value) {
                                  setMenuState(() {
                                    if (value == true) {
                                      _tempSelectedDays.add(day);
                                    } else {
                                      _tempSelectedDays.remove(day);
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        key: _dropdownKey,
        onTap: _showOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getWorkingDaysText(),
                  style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(CupertinoIcons.chevron_down, color: CupertinoColors.placeholderText),
            ],
          ),
        ),
      ),
    );
  }
}
