part of '../inventory_journal_page.dart';

class _JournalFilterSheet extends StatefulWidget {
  const _JournalFilterSheet({
    required this.branchOptions,
    required this.stockItems,
    required this.initialDraft,
  });

  final List<MapEntry<String, String>> branchOptions;
  final List<StockItem> stockItems;
  final _JournalFilterDraft initialDraft;

  @override
  State<_JournalFilterSheet> createState() => _JournalFilterSheetState();
}

class _JournalFilterSheetState extends State<_JournalFilterSheet> {
  late String _branchId;
  late String _stockItemId;
  late String _stockItemName;
  InventoryJournalReasonFilter? _reasonFilter;
  late InventoryJournalDatePreset _datePreset;
  late DateTime _startDate;
  late DateTime _endDate;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _branchId = widget.initialDraft.branchId;
    _stockItemId = widget.initialDraft.stockItemId;
    _stockItemName = widget.initialDraft.stockItemName;
    _reasonFilter = widget.initialDraft.reasonFilter;
    _datePreset = widget.initialDraft.datePreset;
    _startDate = widget.initialDraft.startDate;
    _endDate = widget.initialDraft.endDate;
    _startController = TextEditingController(
      text: formatYyyyMmDd(widget.initialDraft.startDate),
    );
    _endController = TextEditingController(
      text: formatYyyyMmDd(widget.initialDraft.endDate),
    );
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = AppBreakpoints.isSmall(
      MediaQuery.sizeOf(context).width,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Filter journal',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (!isSmallScreen)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _appliedFilterSummaryLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
              TextButton(
                onPressed: _appliedFilterCount == 0 ? null : _clearFilters,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Clear filters'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Date range',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in InventoryJournalDatePreset.values)
                ChoiceChip(
                  label: Text(_presetLabel(preset)),
                  selected: _datePreset == preset,
                  onSelected: (_) => _handlePresetSelection(preset),
                ),
            ],
          ),
          if (_datePreset == InventoryJournalDatePreset.custom) ...[
            const SizedBox(height: 12),
            if (isSmallScreen) ...[
              InventoryJournalDateField(
                controller: _startController,
                label: 'Start date',
                onTap: () => _pickDate(isStart: true),
                onClear: () => _clearDate(isStart: true),
                allowClear: false,
              ),
              const SizedBox(height: 12),
              InventoryJournalDateField(
                controller: _endController,
                label: 'End date',
                onTap: () => _pickDate(isStart: false),
                onClear: () => _clearDate(isStart: false),
                allowClear: false,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: InventoryJournalDateField(
                      controller: _startController,
                      label: 'Start date',
                      onTap: () => _pickDate(isStart: true),
                      onClear: () => _clearDate(isStart: true),
                      allowClear: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InventoryJournalDateField(
                      controller: _endController,
                      label: 'End date',
                      onTap: () => _pickDate(isStart: false),
                      onClear: () => _clearDate(isStart: false),
                      allowClear: false,
                    ),
                  ),
                ],
              ),
            ],
            if (_validationMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _validationMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            'Item',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _JournalItemAutocompleteField(
            items: widget.stockItems,
            selectedItemId: _stockItemId,
            initialText: _stockItemName,
            onSelected: (item) {
              setState(() {
                _stockItemId = item.id;
                _stockItemName = item.name;
              });
            },
            onCleared: () {
              setState(() {
                _stockItemId = '';
                _stockItemName = '';
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Branch',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _DialogDropdown<String>(
            value: _branchId,
            entries: widget.branchOptions
                .map(
                  (entry) => DropdownMenuEntry<String>(
                    value: entry.key,
                    label: entry.value,
                  ),
                )
                .toList(growable: false),
            onSelected: (value) => setState(() => _branchId = value ?? 'all'),
          ),
          const SizedBox(height: 16),
          Text(
            'Movement type',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _DialogDropdown<InventoryJournalReasonFilter?>(
            value: _reasonFilter,
            entries: <DropdownMenuEntry<InventoryJournalReasonFilter?>>[
              const DropdownMenuEntry<InventoryJournalReasonFilter?>(
                value: null,
                label: 'All types',
              ),
              ...InventoryJournalReasonFilter.values.map(
                (filter) => DropdownMenuEntry<InventoryJournalReasonFilter?>(
                  value: filter,
                  label: filter.label,
                ),
              ),
            ],
            onSelected: (value) => setState(() => _reasonFilter = value),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: AppTheme.cancelActionButtonStyle,
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int get _appliedFilterCount {
    var count = 0;
    if (_datePreset != InventoryJournalDatePreset.today) count += 1;
    if (_stockItemId.isNotEmpty) count += 1;
    if (_branchId != 'all') count += 1;
    if (_reasonFilter != null) count += 1;
    return count;
  }

  String get _appliedFilterSummaryLabel {
    final count = _appliedFilterCount;
    return count == 1 ? '1 filter applied' : '$count filters applied';
  }

  void _clearFilters() {
    final range = _rangeForPreset(InventoryJournalDatePreset.today);
    setState(() {
      _branchId = 'all';
      _stockItemId = '';
      _stockItemName = '';
      _reasonFilter = null;
      _datePreset = InventoryJournalDatePreset.today;
      _startDate = range.start;
      _endDate = range.end;
      _validationMessage = null;
      _syncDateControllers();
    });
  }

  void _handlePresetSelection(InventoryJournalDatePreset preset) {
    if (preset != InventoryJournalDatePreset.custom) {
      final range = _rangeForPreset(preset);
      setState(() {
        _datePreset = preset;
        _startDate = range.start;
        _endDate = range.end;
        _validationMessage = null;
        _syncDateControllers();
      });
      return;
    }
    setState(() {
      _datePreset = InventoryJournalDatePreset.custom;
      _validationMessage = null;
      _syncDateControllers();
    });
  }

  void _apply() {
    if (_datePreset == InventoryJournalDatePreset.custom) {
      final validationMessage = _validateCustomRange(_startDate, _endDate);
      if (validationMessage != null) {
        setState(() => _validationMessage = validationMessage);
        return;
      }
    }
    Navigator.of(context).pop(
      _JournalFilterDraft(
        branchId: _branchId,
        stockItemId: _stockItemId,
        stockItemName: _stockItemName,
        reasonFilter: _reasonFilter,
        datePreset: _datePreset,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  void _clearDate({required bool isStart}) {
    setState(() {
      _validationMessage = null;
      if (isStart) {
        _startDate = _startOfDay(DateTime.now());
      } else {
        _endDate = _endOfDay(DateTime.now());
      }
      _syncDateControllers();
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _validationMessage = null;
      if (isStart) {
        _startDate = _startOfDay(picked);
      } else {
        _endDate = _endOfDay(picked);
      }
      _syncDateControllers();
    });
  }

  void _syncDateControllers() {
    _startController.text = formatYyyyMmDd(_startDate);
    _endController.text = formatYyyyMmDd(_endDate);
  }
}

class _DialogDropdown<T> extends StatelessWidget {
  const _DialogDropdown({
    required this.value,
    required this.entries,
    required this.onSelected,
  });

  final T value;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxMenuHeight = _filterOverlayMaxHeight(context);
        return DropdownMenu<T>(
          width: constraints.hasBoundedWidth ? constraints.maxWidth : null,
          menuHeight: maxMenuHeight,
          menuStyle: const MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            surfaceTintColor: WidgetStatePropertyAll(Colors.white),
          ),
          initialSelection: value,
          dropdownMenuEntries: entries,
          onSelected: onSelected,
        );
      },
    );
  }
}

class _JournalItemAutocompleteField extends StatefulWidget {
  const _JournalItemAutocompleteField({
    required this.items,
    required this.selectedItemId,
    required this.initialText,
    required this.onSelected,
    required this.onCleared,
  });

  final List<StockItem> items;
  final String selectedItemId;
  final String initialText;
  final ValueChanged<StockItem> onSelected;
  final VoidCallback onCleared;

  @override
  State<_JournalItemAutocompleteField> createState() =>
      _JournalItemAutocompleteFieldState();
}

class _JournalItemAutocompleteFieldState
    extends State<_JournalItemAutocompleteField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant _JournalItemAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedItemId != widget.selectedItemId ||
        oldWidget.initialText != widget.initialText) {
      _controller.value = TextEditingValue(
        text: widget.initialText,
        selection: TextSelection.collapsed(offset: widget.initialText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 320.0;
        final maxMenuHeight = _filterOverlayMaxHeight(context);
        return RawAutocomplete<StockItem>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (option) => option.name,
          optionsBuilder: (textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.isEmpty) return widget.items;
            return widget.items.where((item) {
              final name = item.name.toLowerCase();
              final baseUnit = item.baseUnit.toLowerCase();
              return name.contains(query) || baseUnit.contains(query);
            });
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search stock item',
                    suffixIcon: textController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear',
                            onPressed: () {
                              textController.clear();
                              widget.onCleared();
                            },
                          ),
                  ),
                  onTap: () {
                    textController.value = TextEditingValue(
                      text: textController.text,
                      selection: TextSelection.collapsed(
                        offset: textController.text.length,
                      ),
                    );
                  },
                  onChanged: (_) {
                    if (widget.selectedItemId.isNotEmpty) {
                      widget.onCleared();
                    }
                    setState(() {});
                  },
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            final optionList = options.toList(growable: false);
            if (optionList.isEmpty) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: fieldWidth,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxMenuHeight),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: optionList.length,
                      itemBuilder: (context, index) {
                        final option = optionList[index];
                        return ListTile(
                          title: Text(option.name),
                          subtitle: Text(option.baseUnit),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
          onSelected: widget.onSelected,
        );
      },
    );
  }
}
