import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/media/product_image_picker.dart';
import 'package:modular_pos/features/auth/domain/active_branch_context_provider.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_controller.dart';
import 'package:modular_pos/features/branchV2/ui/viewmodels/branch_state.dart';
import 'package:modular_pos/features/inventory/ui/viewmodels/stock_inventory_controller.dart';
import 'package:modular_pos/features/menu/domain/models/menu_composition.dart';
import 'package:modular_pos/features/menu/domain/models/menu_branch.dart';
import 'package:modular_pos/features/menu/domain/models/menu_category.dart';
import 'package:modular_pos/features/menu/domain/models/menu_item.dart';
import 'package:modular_pos/features/menu/domain/models/menu_modifier_option_effect.dart';
import 'package:modular_pos/features/menu/domain/models/modifier_group.dart';
import 'package:modular_pos/features/menu/ui/components/menu_form_field_label.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_error_mapper.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/menu_item_form_utils.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/widgets/menu_item_composition_section.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/widgets/menu_item_modifier_effects_section.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/widgets/menu_section_action_button.dart';
import 'package:modular_pos/features/menu/ui/view/menu_item_form/widgets/selection_chips_field.dart';
import 'package:modular_pos/features/menu/ui/viewmodels/menu_viewmodel.dart';

class MenuItemFormPage extends ConsumerStatefulWidget {
  const MenuItemFormPage({super.key, this.initialItem});

  final MenuItem? initialItem;

  @override
  ConsumerState<MenuItemFormPage> createState() => _MenuItemFormPageState();
}

enum _MenuItemFormMode { create, view, edit }

class _MenuItemFormPageState extends ConsumerState<MenuItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  String? _selectedCategoryId;
  final Set<String> _selectedModifierGroupIds = {};
  final Set<String> _selectedBranchIds = {};
  bool _hasInitializedBranchSelection = false;

  String? _selectedImagePath;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();
  _MenuItemFormMode _mode = _MenuItemFormMode.create;

  bool _isSaving = false;
  bool _isActive = true;
  final List<MenuItemCompositionDraft> _compositionRows = [];
  final Map<String, List<MenuItemCompositionDraft>> _modifierEffectRowsByOptionId =
      {};
  bool _didInitializeComposition = false;
  bool _didInitializeModifierEffects = false;
  bool _compositionDirty = false;
  bool _modifierEffectsDirty = false;

  bool get isCreate => _mode == _MenuItemFormMode.create;
  bool get isView => _mode == _MenuItemFormMode.view;
  bool get isEditing => _mode != _MenuItemFormMode.view;

  String get _title => switch (_mode) {
    _MenuItemFormMode.create => 'Add menu item',
    _MenuItemFormMode.view => 'Menu item details',
    _MenuItemFormMode.edit => 'Edit menu item',
  };

  @override
  void initState() {
    super.initState();
    _mode = widget.initialItem == null
        ? _MenuItemFormMode.create
        : _MenuItemFormMode.view;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(menuViewModelProvider.notifier).loadMenu();
      ref.read(stockInventoryControllerProvider.notifier).loadStockItems();
      _bootstrapCompositionState();
      _bootstrapModifierEffectsState();
    });

    _nameController = TextEditingController(
      text: widget.initialItem?.name ?? '',
    );
    _priceController = TextEditingController(
      text: widget.initialItem?.price.toStringAsFixed(2) ?? '',
    );

    _selectedCategoryId = widget.initialItem?.categoryId;
    _selectedModifierGroupIds.addAll(
      widget.initialItem?.modifierGroupIds ?? const [],
    );
    _selectedBranchIds.addAll(widget.initialItem?.branchIds ?? const []);
    _hasInitializedBranchSelection = _selectedBranchIds.isNotEmpty;
    _existingImageUrl = widget.initialItem?.imageUrl;
    _isActive = widget.initialItem?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuViewModelProvider);
    final inventoryState = ref.watch(stockInventoryControllerProvider);
    final categories = state.categories;
    final modifierGroups = state.modifierGroups;
    final branches = state.branches;
    final stockItems = inventoryState.stockItems.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
    final compositionItemId = widget.initialItem?.id;
    final compositionLoading =
        compositionItemId != null &&
        state.compositionLoadingByItem[compositionItemId] == true;
    final compositionError = compositionItemId == null
        ? null
        : state.compositionErrors[compositionItemId];
    final modifierEffectsLoading =
        compositionItemId != null &&
        state.modifierOptionEffectsLoadingByItemId[compositionItemId] == true;
    final modifierEffectsError = compositionItemId == null
        ? null
        : state.modifierOptionEffectsErrorsByItemId[compositionItemId];
    final baseComposition = compositionItemId == null
        ? const <MenuComponent>[]
        : state.baseCompositionByItemId[compositionItemId] ??
            const <MenuComponent>[];
    final modifierEffects = compositionItemId == null
        ? const <MenuModifierOptionEffect>[]
        : state.modifierOptionEffectsByItemId[compositionItemId] ??
            const <MenuModifierOptionEffect>[];
    final selectedModifierGroups = modifierGroups
        .where((group) => _selectedModifierGroupIds.contains(group.id))
        .toList(growable: false);
    final inheritedEffectsByOptionId = {
      for (final option in selectedModifierGroups.expand((group) => group.options))
        if (!_modifierEffectRowsByOptionId.containsKey(option.id) &&
            option.componentDeltas.isNotEmpty)
          option.id: option.componentDeltas,
    };

    if (!_didInitializeComposition &&
        compositionItemId != null &&
        state.compositionLoadedByItem[compositionItemId] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didInitializeComposition) return;
        _replaceCompositionRows(baseComposition);
        setState(() {
          _didInitializeComposition = true;
          _compositionDirty = false;
        });
      });
    }
    if (!_didInitializeModifierEffects && compositionItemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didInitializeModifierEffects) return;
        _replaceModifierEffectRows(modifierEffects);
        setState(() {
          _didInitializeModifierEffects = true;
          _modifierEffectsDirty = false;
        });
      });
    }
    if (!_hasInitializedBranchSelection &&
        _selectedBranchIds.isEmpty &&
        branches.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedBranchIds.isNotEmpty) return;
        setState(() {
          _selectedBranchIds.addAll(branches.map((b) => b.id));
          _hasInitializedBranchSelection = true;
        });
      });
    }

    final branchNameLookup = {
      for (final branch in branches) branch.id: branch.name,
    };
    final modifierNameLookup = {
      for (final group in modifierGroups) group.id: group.name,
    };
    final isMobileLayout = MediaQuery.of(context).size.width < 640;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        title: Text(_title),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionSpacer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wideSection = constraints.maxWidth >= 900;
                  if (wideSection) {
                    return _MenuSectionCard(
                      title: 'Item',
                      description: 'Image and basic information',
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: ProductImagePicker(
                                  size: const Size(220, 220),
                                  borderRadius: 16,
                                  imageBytes: _selectedImageBytes,
                                  imageUrl: _selectedImageBytes == null
                                      ? _existingImageUrl
                                      : null,
                                  readOnly: !isEditing,
                                  onPickImage: _pickImage,
                                  onClearLocalSelection:
                                      _selectedImageBytes != null
                                      ? isEditing
                                            ? () => setState(() {
                                                _selectedImageBytes = null;
                                                _selectedImagePath = null;
                                              })
                                            : null
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: Column(
                                children: _buildItemDetailFields(
                                  categories,
                                  isWide: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _MenuSectionCard(
                        title: 'Item image',
                        children: [
                          Center(
                            child: ProductImagePicker(
                              size: const Size(220, 220),
                              borderRadius: 16,
                              imageBytes: _selectedImageBytes,
                              imageUrl: _selectedImageBytes == null
                                  ? _existingImageUrl
                                  : null,
                              readOnly: !isEditing,
                              onPickImage: _pickImage,
                              onClearLocalSelection: _selectedImageBytes != null
                                  ? isEditing
                                        ? () => setState(() {
                                            _selectedImageBytes = null;
                                            _selectedImagePath = null;
                                          })
                                        : null
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MenuSectionCard(
                        title: 'Item details',
                        description: 'Basic information about the menu item.',
                        children: _buildItemDetailFields(
                          categories,
                          isWide: false,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _SectionSpacer(
              child: _MenuSectionCard(
                title: 'Assign branch',
                description: 'Select which branches provide this item.',
                headerAction: isEditing && branches.isNotEmpty && !isMobileLayout
                    ? _SectionHeaderButton(
                        label: 'Select branches',
                        onPressed: () => _showBranchSelection(branches),
                        showAddIcon: false,
                      )
                    : null,
                children: [
                  if (branches.isEmpty)
                    Text(
                      'No branches available.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    )
                  else
                    SelectionChipsField(
                      selectedIds: _selectedBranchIds,
                      addButtonLabel: 'Select branches',
                      labelResolver: (id) =>
                          branchNameLookup[id] ?? 'Unknown branch',
                      onAddTap: () => _showBranchSelection(branches),
                      onRemove: (id) =>
                          setState(() => _selectedBranchIds.remove(id)),
                      editable: isEditing,
                      showAddButton: false,
                    ),
                  if (isEditing && branches.isNotEmpty && isMobileLayout) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _SectionHeaderButton(
                        label: 'Select branches',
                        onPressed: () => _showBranchSelection(branches),
                        showAddIcon: false,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _SectionSpacer(
              child: _MenuSectionCard(
                title: 'Modifier groups',
                description: 'Assign modifier groups for this item.',
                headerAction:
                    isEditing && modifierGroups.isNotEmpty && !isMobileLayout
                    ? _SectionHeaderButton(
                        label: 'Add modifier',
                        onPressed: () => _showModifierSelection(modifierGroups),
                      )
                    : null,
                children: [
                  if (modifierGroups.isEmpty)
                    Text(
                      'No modifier groups. Add one first.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    )
                  else
                    SelectionChipsField(
                      selectedIds: _selectedModifierGroupIds,
                      addButtonLabel: 'Add modifier',
                      labelResolver: (id) =>
                          modifierNameLookup[id] ?? 'Unknown',
                      onAddTap: () => _showModifierSelection(modifierGroups),
                      onRemove: (id) =>
                          setState(() => _selectedModifierGroupIds.remove(id)),
                      editable: isEditing,
                      showAddButton: false,
                    ),
                  if (isEditing &&
                      modifierGroups.isNotEmpty &&
                      isMobileLayout) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _SectionHeaderButton(
                        label: 'Add modifier',
                        onPressed: () => _showModifierSelection(modifierGroups),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _SectionSpacer(
              child: MenuItemModifierEffectsSection(
                modifierGroups: selectedModifierGroups,
                effectRowsByOptionId: _modifierEffectRowsByOptionId,
                inheritedEffectsByOptionId: inheritedEffectsByOptionId,
                stockItems: stockItems,
                isEditing: isEditing && !isCreate,
                isLoading: modifierEffectsLoading,
                errorText: modifierEffectsError,
                helperText: isCreate
                    ? 'Optional. Save the item first, then open it again if you want to configure item-scoped modifier effects.'
                    : 'Optional. Use item-scoped option effects only when a modifier option should add or remove components for this menu item.',
                emptyText: isCreate
                    ? 'Modifier option effects become available after the item is created.'
                    : 'No item-scoped modifier effects configured for the selected modifier groups.',
                onAddRow: isCreate ? null : _addModifierEffectRow,
                onRemoveRow: isCreate ? null : _removeModifierEffectRow,
                onStockItemChanged: isCreate
                    ? null
                    : _updateModifierEffectStockItem,
                onTrackingModeChanged: isCreate
                    ? null
                    : _updateModifierEffectTrackingMode,
              ),
            ),
            _SectionSpacer(
              child: MenuItemCompositionSection(
                rows: _compositionRows,
                stockItems: stockItems,
                isEditing: isEditing && !isCreate,
                isLoading: compositionLoading,
                errorText: compositionError,
                helperText: isCreate
                    ? 'Optional. Save the item first, then open it again if you want to configure base components.'
                    : 'Optional. Base components stay with the menu item and modifier options can adjust them later.',
                emptyText: isCreate
                    ? 'Composition becomes available after the item is created.'
                    : 'No base components configured yet.',
                onAddRow: isCreate ? null : _addCompositionRow,
                onRemoveRow: isCreate ? null : _removeCompositionRow,
                onStockItemChanged: isCreate ? null : _updateCompositionStockItem,
                onTrackingModeChanged: isCreate ? null : _updateCompositionTrackingMode,
              ),
            ),
            _SectionSpacer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _MenuActionRow(
                  isView: isView,
                  isActive: _isActive,
                  isSaving: _isSaving,
                  isCreate: isCreate,
                  onCancel: _handleCancel,
                  onSave: _save,
                  onEdit: () => setState(() => _mode = _MenuItemFormMode.edit),
                  onToggleActive: _toggleActiveState,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemDetailFields(
    List<MenuCategory> categories, {
    required bool isWide,
  }) {
    final isSmallScreen = AppBreakpoints.isSmall(
      MediaQuery.of(context).size.width,
    );
    final nameField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MenuFormFieldLabel(text: 'Item name', isRequired: true),
        TextFormField(
          controller: _nameController,
          maxLength: 20,
          readOnly: !isEditing,
          enabled: isEditing,
          decoration: const InputDecoration(hintText: 'Enter item name'),
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
    final priceField = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MenuFormFieldLabel(text: 'Base price', isRequired: true),
        TextFormField(
          controller: _priceController,
          readOnly: !isEditing,
          enabled: isEditing,
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Text(
                '\$',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            _TwoDecimalTextInputFormatter(),
          ],
          validator: (value) {
            final text = (value ?? '').trim();
            if (text.isEmpty) return 'Required';
            final parsed = double.tryParse(text);
            if (parsed == null) return 'Invalid price';
            if (parsed < 0) return 'Must be >= 0';
            return null;
          },
        ),
      ],
    );
    final categoryField = LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenuTheme(
          data: DropdownMenuThemeData(
            menuStyle: MenuStyle(
              backgroundColor: const WidgetStatePropertyAll(Colors.white),
              fixedSize: WidgetStatePropertyAll(
                Size(constraints.maxWidth, double.nan),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MenuFormFieldLabel(text: 'Category', isOptional: true),
              DropdownMenu<String>(
                width: constraints.maxWidth,
                initialSelection: _selectedCategoryId ?? '',
                enabled: isEditing,
                onSelected: isEditing
                    ? (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      }
                    : null,
                dropdownMenuEntries: [
                  const DropdownMenuEntry<String>(
                    value: '',
                    label: 'Uncategorized',
                  ),
                  ...categories.map<DropdownMenuEntry<String>>(
                    (category) => DropdownMenuEntry<String>(
                      value: category.id,
                      label: category.name,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return [
      if (isSmallScreen) ...[
        nameField,
        const SizedBox(height: 16),
        priceField,
      ] else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: isWide ? 2 : 1, child: nameField),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: priceField),
          ],
        ),
      const SizedBox(height: 16),
      categoryField,
    ];
  }
  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final availableBranches = ref.read(menuViewModelProvider).branches;
    if (availableBranches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No branch options are available. Please reload and try again.',
          ),
        ),
      );
      return;
    }

    if (_selectedBranchIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one branch before saving.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(menuViewModelProvider.notifier);
      final menuState = ref.read(menuViewModelProvider);
      final resolvedEditItemId = _mode == _MenuItemFormMode.edit
          ? _resolveEditItemId()
          : null;
      final selectedModifierGroups = menuState.modifierGroups
          .where((group) => _selectedModifierGroupIds.contains(group.id))
          .toList(growable: false);
      final compositionPayload = _buildCompositionPayload();
      final modifierEffectPayload = _buildModifierEffectPayload(
        selectedModifierGroups,
      );
      var activeBranchContextId =
          (ref.read(activeBranchContextIdProvider) ?? '').trim();
      var hasBranchContext = activeBranchContextId.isNotEmpty;
      final trackedModifierEffectsRequireBranch = modifierEffectPayload.any(
        (effect) => effect.components.any(
          (component) => component.trackingMode.trim().toUpperCase() == 'TRACKED',
        ),
      );
      final branchContextNeeded =
          _compositionDirty ||
          (_modifierEffectsDirty && trackedModifierEffectsRequireBranch);
      if (branchContextNeeded && !hasBranchContext) {
        final resolvedBranchId = _resolveBranchContextForSave();
        if (resolvedBranchId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Select at least one valid branch before saving composition or tracked modifier effects.',
              ),
            ),
          );
          return;
        }
        final selectionResult = await ref
            .read(branchControllerProvider.notifier)
            .onBranchTileTap(branchId: resolvedBranchId);
        if (selectionResult != BranchSelectionResult.success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to switch into a branch context for saving composition changes.',
              ),
            ),
          );
          return;
        }
        activeBranchContextId =
            (ref.read(activeBranchContextIdProvider) ?? '').trim();
        hasBranchContext = activeBranchContextId.isNotEmpty;
        if (!hasBranchContext) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Branch context is still missing after branch selection.',
              ),
            ),
          );
          return;
        }
      }
      if (_mode == _MenuItemFormMode.edit &&
          (resolvedEditItemId ?? '').trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to resolve menu item id. Please try again.'),
          ),
        );
        return;
      }
      final item = MenuItem(
        id: _mode == _MenuItemFormMode.edit ? resolvedEditItemId ?? '' : '',
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId ?? '',
        price: double.parse(_priceController.text.trim()),
        imageUrl: widget.initialItem?.imageUrl,
        modifierGroupIds: _selectedModifierGroupIds.toList(),
        description: widget.initialItem?.description ?? '',
        branchIds: _selectedBranchIds.toList(growable: false),
        isActive: _isActive,
      );

      MenuItem saved;
      if (_mode == _MenuItemFormMode.edit) {
        if (_hasBaseItemChanges(item)) {
          saved = await notifier.updateMenuItem(
            item,
            imagePath: kIsWeb ? null : _selectedImagePath,
            imageBytes: _selectedImageBytes,
          );
        } else {
          saved = widget.initialItem ?? item;
        }
      } else {
        saved = await notifier.addMenuItem(
          item,
          imagePath: kIsWeb ? null : _selectedImagePath,
          imageBytes: _selectedImageBytes,
        );
      }

      if (!isCreate) {
        if (_compositionDirty) {
          await notifier.upsertItemComposition(
            menuItemId: saved.id,
            baseComponents: compositionPayload,
          );
          _compositionDirty = false;
        }
        if (_modifierEffectsDirty) {
          await notifier.upsertItemModifierOptionEffects(
            menuItemId: saved.id,
            effects: modifierEffectPayload,
          );
          _modifierEffectsDirty = false;
        }
      }

      await notifier.loadMenuItemDetail(saved.id);
      if (mounted) context.pop(saved);
    } catch (e) {
      if (!mounted) return;
      final compositionMessage = widget.initialItem == null
          ? null
          : ref.read(menuViewModelProvider).compositionErrors[
              widget.initialItem!.id
            ];
      final effectMessage = widget.initialItem == null
          ? null
          : ref
                .read(menuViewModelProvider)
                .modifierOptionEffectsErrorsByItemId[widget.initialItem!.id];
      final message =
          effectMessage ?? compositionMessage ?? mapMenuItemSaveErrorMessage(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImagePath = picked.path;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image picker not available. Please fully restart the app after running flutter pub get.',
          ),
        ),
      );
    }
  }

  void _handleCancel() {
    if (_mode == _MenuItemFormMode.create) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_mode == _MenuItemFormMode.edit) {
      setState(_resetToView);
    }
  }

  void _resetToView() {
    _mode = _MenuItemFormMode.view;
    _isSaving = false;
    _selectedImageBytes = null;
    _selectedImagePath = null;
    _nameController.text = widget.initialItem?.name ?? '';
    _priceController.text = widget.initialItem?.price.toStringAsFixed(2) ?? '';
    _selectedCategoryId = widget.initialItem?.categoryId;
    _selectedModifierGroupIds
      ..clear()
      ..addAll(widget.initialItem?.modifierGroupIds ?? const []);
    _selectedBranchIds
      ..clear()
      ..addAll(widget.initialItem?.branchIds ?? const []);
    _existingImageUrl = widget.initialItem?.imageUrl;
    _isActive = widget.initialItem?.isActive ?? true;
    _restoreCompositionDrafts();
    _restoreModifierEffectDrafts();
  }

  Future<void> _toggleActiveState() async {
    final current = widget.initialItem;
    if (current == null) return;
    if (_isActive) {
      final confirmed = await _confirmArchive();
      if (!confirmed) return;
    }
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(menuViewModelProvider.notifier);
      if (_isActive) {
        await notifier.archiveMenuItem(current.id);
      } else {
        await notifier.restoreMenuItem(current.id);
      }
      if (!mounted) return;
      setState(() => _isActive = !_isActive);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isActive ? 'Menu item restored' : 'Menu item archived',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item status: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmArchive() async {
    final cancelStyle = AppTheme.cancelActionButtonStyle;
    final archiveStyle = FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Archive menu item?'),
        content: Text(
          '"${widget.initialItem?.name ?? _nameController.text.trim()}" will be archived and removed from active menu items.',
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: cancelStyle,
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: archiveStyle,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Archive'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showModifierSelection(List<ModifierGroup> groups) async {
    final useDialog = AppBreakpoints.isLarge(
      MediaQuery.of(context).size.width,
    );
    await showCheckboxSelectionSheet<ModifierGroup>(
      context: context,
      title: 'Select modifier groups',
      items: groups,
      selectedValues: _selectedModifierGroupIds,
      idBuilder: (group) => group.id,
      titleBuilder: (group) => group.name,
      subtitleBuilder: (group) =>
          '${group.options.length} options - ${group.selectionType == 'single' ? 'Single' : 'Multiple'}',
      useDialog: useDialog,
      onApply: (selection) {
        setState(() {
          _selectedModifierGroupIds
            ..clear()
            ..addAll(selection);
        });
      },
    );
  }

  Future<void> _showBranchSelection(List<MenuBranch> branches) async {
    final useDialog = !AppBreakpoints.isSmall(MediaQuery.of(context).size.width);
    await showCheckboxSelectionSheet<MenuBranch>(
      context: context,
      title: 'Select branches',
      items: branches,
      selectedValues: _selectedBranchIds,
      idBuilder: (branch) => branch.id,
      titleBuilder: (branch) => branch.name,
      useDialog: useDialog,
      showSelectAllAction: true,
      selectAllLabel: 'Apply all branches',
      clearAllLabel: 'Clear all branches',
      onApply: (selection) {
        setState(() {
          _selectedBranchIds
            ..clear()
            ..addAll(selection);
          _hasInitializedBranchSelection = true;
        });
      },
    );
  }

  Future<void> _bootstrapCompositionState() async {
    final item = widget.initialItem;
    if (item == null || item.id.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _didInitializeComposition = true;
          _compositionDirty = false;
        });
      }
      return;
    }

    final cached = ref.read(menuViewModelProvider).baseCompositionByItemId[
      item.id
    ];
    if (cached != null) {
      _replaceCompositionRows(cached);
      if (mounted) {
        setState(() {
          _didInitializeComposition = true;
          _compositionDirty = false;
        });
      }
      return;
    }

    try {
      await ref.read(menuViewModelProvider.notifier).loadItemComposition(item.id);
    } catch (_) {
      // Error state is already stored in the viewmodel for the section UI.
    }

    if (!mounted) return;
    final nextComponents =
        ref.read(menuViewModelProvider).baseCompositionByItemId[item.id] ??
        const <MenuComponent>[];
    _replaceCompositionRows(nextComponents);
    setState(() {
      _didInitializeComposition = true;
      _compositionDirty = false;
    });
  }

  Future<void> _bootstrapModifierEffectsState() async {
    final item = widget.initialItem;
    if (item == null || item.id.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _didInitializeModifierEffects = true;
          _modifierEffectsDirty = false;
        });
      }
      return;
    }

    final cached =
        ref.read(menuViewModelProvider).modifierOptionEffectsByItemId[item.id];
    if (cached != null) {
      _replaceModifierEffectRows(cached);
      if (mounted) {
        setState(() {
          _didInitializeModifierEffects = true;
          _modifierEffectsDirty = false;
        });
      }
      return;
    }

    try {
      await ref.read(menuViewModelProvider.notifier).loadMenuItemDetail(item.id);
    } catch (_) {
      // Error state is already stored in the viewmodel for the section UI.
    }

    if (!mounted) return;
    final nextEffects =
        ref.read(menuViewModelProvider).modifierOptionEffectsByItemId[item.id] ??
        const <MenuModifierOptionEffect>[];
    _replaceModifierEffectRows(nextEffects);
    setState(() {
      _didInitializeModifierEffects = true;
      _modifierEffectsDirty = false;
    });
  }

  void _restoreCompositionDrafts() {
    final itemId = widget.initialItem?.id;
    if (itemId == null || itemId.trim().isEmpty) {
      _replaceCompositionRows(const []);
      _compositionDirty = false;
      return;
    }
    final cached =
        ref.read(menuViewModelProvider).baseCompositionByItemId[itemId] ??
        const <MenuComponent>[];
    _replaceCompositionRows(cached);
    _compositionDirty = false;
  }

  void _restoreModifierEffectDrafts() {
    final itemId = widget.initialItem?.id;
    if (itemId == null || itemId.trim().isEmpty) {
      _replaceModifierEffectRows(const []);
      _modifierEffectsDirty = false;
      return;
    }
    final cached =
        ref.read(menuViewModelProvider).modifierOptionEffectsByItemId[itemId] ??
        const <MenuModifierOptionEffect>[];
    _replaceModifierEffectRows(cached);
    _modifierEffectsDirty = false;
  }

  void _replaceCompositionRows(List<MenuComponent> components) {
    for (final row in _compositionRows) {
      row.dispose();
    }
    _compositionRows
      ..clear()
      ..addAll(
        components.map(
          (component) => MenuItemCompositionDraft(
            stockItemId: component.stockItemId,
            quantity: component.quantityInBaseUnit.toString(),
            trackingMode: component.trackingMode.isEmpty
                ? 'TRACKED'
                : component.trackingMode == 'UNTRACKED'
                    ? 'NOT_TRACKED'
                    : component.trackingMode,
          ),
        ).map(_attachCompositionDraftListener),
      );
  }

  void _replaceModifierEffectRows(List<MenuModifierOptionEffect> effects) {
    for (final rows in _modifierEffectRowsByOptionId.values) {
      for (final row in rows) {
        row.dispose();
      }
    }
    _modifierEffectRowsByOptionId
      ..clear()
      ..addEntries(
        effects.map(
          (effect) => MapEntry(
            effect.modifierOptionId,
            effect.components
                .map(
                  (component) => MenuItemCompositionDraft(
                    stockItemId: component.stockItemId,
                    quantity: component.quantityDeltaInBaseUnit.toString(),
                    trackingMode: component.trackingMode.isEmpty
                        ? 'TRACKED'
                        : component.trackingMode == 'UNTRACKED'
                            ? 'NOT_TRACKED'
                            : component.trackingMode,
                  ),
                )
                .map(_attachModifierEffectDraftListener)
                .toList(growable: false),
          ),
        ),
      );
  }

  void _addCompositionRow() {
    setState(() {
      _compositionRows.add(
        _attachCompositionDraftListener(MenuItemCompositionDraft()),
      );
      _compositionDirty = true;
    });
  }

  void _removeCompositionRow(String rowId) {
    setState(() {
      final index = _compositionRows.indexWhere((row) => row.id == rowId);
      if (index == -1) return;
      _compositionRows[index].dispose();
      _compositionRows.removeAt(index);
      _compositionDirty = true;
    });
  }

  void _updateCompositionStockItem(String rowId, String? stockItemId) {
    setState(() {
      for (final row in _compositionRows) {
        if (row.id == rowId) {
          row.selectedStockItemId = stockItemId;
          _compositionDirty = true;
          return;
        }
      }
    });
  }

  void _updateCompositionTrackingMode(String rowId, String trackingMode) {
    setState(() {
      for (final row in _compositionRows) {
        if (row.id == rowId) {
          row.trackingMode = trackingMode;
          _compositionDirty = true;
          return;
        }
      }
    });
  }

  void _addModifierEffectRow(String optionId) {
    setState(() {
      final rows = _modifierEffectRowsByOptionId.putIfAbsent(
        optionId,
        () => <MenuItemCompositionDraft>[],
      );
      rows.add(
        _attachModifierEffectDraftListener(
          MenuItemCompositionDraft(quantity: '0'),
        ),
      );
      _modifierEffectsDirty = true;
    });
  }

  void _removeModifierEffectRow(String optionId, String rowId) {
    setState(() {
      final rows = _modifierEffectRowsByOptionId[optionId];
      if (rows == null) return;
      final index = rows.indexWhere((row) => row.id == rowId);
      if (index == -1) return;
      rows[index].dispose();
      rows.removeAt(index);
      if (rows.isEmpty) {
        _modifierEffectRowsByOptionId.remove(optionId);
      }
      _modifierEffectsDirty = true;
    });
  }

  void _updateModifierEffectStockItem(
    String optionId,
    String rowId,
    String? stockItemId,
  ) {
    setState(() {
      for (final row in _modifierEffectRowsByOptionId[optionId] ??
          const <MenuItemCompositionDraft>[]) {
        if (row.id == rowId) {
          row.selectedStockItemId = stockItemId;
          _modifierEffectsDirty = true;
          return;
        }
      }
    });
  }

  void _updateModifierEffectTrackingMode(
    String optionId,
    String rowId,
    String trackingMode,
  ) {
    setState(() {
      for (final row in _modifierEffectRowsByOptionId[optionId] ??
          const <MenuItemCompositionDraft>[]) {
        if (row.id == rowId) {
          row.trackingMode = trackingMode;
          _modifierEffectsDirty = true;
          return;
        }
      }
    });
  }

  List<MenuComponent> _buildCompositionPayload() {
    return _compositionRows
        .map((row) {
          final stockItemId = (row.selectedStockItemId ?? '').trim();
          final quantity = double.tryParse(row.quantityController.text.trim());
          if (stockItemId.isEmpty || quantity == null || quantity <= 0) {
            return null;
          }
          return MenuComponent(
            stockItemId: stockItemId,
            quantityInBaseUnit: quantity,
            trackingMode: row.trackingMode,
          );
        })
        .whereType<MenuComponent>()
        .toList(growable: false);
  }

  List<MenuModifierOptionEffect> _buildModifierEffectPayload(
    List<ModifierGroup> selectedModifierGroups,
  ) {
    final allowedOptionIds = selectedModifierGroups
        .expand((group) => group.options)
        .map((option) => option.id)
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    return _modifierEffectRowsByOptionId.entries
        .where((entry) => allowedOptionIds.contains(entry.key))
        .map((entry) {
          final components = entry.value
              .map((row) {
                final stockItemId = (row.selectedStockItemId ?? '').trim();
                final quantity = double.tryParse(
                  row.quantityController.text.trim(),
                );
                if (stockItemId.isEmpty || quantity == null || quantity <= 0) {
                  return null;
                }
                return ModifierDelta(
                  stockItemId: stockItemId,
                  quantityDeltaInBaseUnit: quantity,
                  trackingMode: row.trackingMode,
                );
              })
              .whereType<ModifierDelta>()
              .toList(growable: false);
          if (components.isEmpty) return null;
          return MenuModifierOptionEffect(
            modifierOptionId: entry.key,
            components: components,
          );
        })
        .whereType<MenuModifierOptionEffect>()
        .toList(growable: false);
  }

  MenuItemCompositionDraft _attachCompositionDraftListener(
    MenuItemCompositionDraft draft,
  ) {
    draft.quantityController.addListener(() {
      if (!mounted) return;
      _compositionDirty = true;
    });
    return draft;
  }

  MenuItemCompositionDraft _attachModifierEffectDraftListener(
    MenuItemCompositionDraft draft,
  ) {
    draft.quantityController.addListener(() {
      if (!mounted) return;
      _modifierEffectsDirty = true;
    });
    return draft;
  }

  bool _hasBaseItemChanges(MenuItem nextItem) {
    final previous = widget.initialItem;
    if (previous == null) return true;

    final nextBranchIds = [...nextItem.branchIds]..sort();
    final previousBranchIds = [...previous.branchIds]..sort();
    final nextModifierGroupIds = [...nextItem.modifierGroupIds]..sort();
    final previousModifierGroupIds = [...previous.modifierGroupIds]..sort();
    final nextImageUrl = (_existingImageUrl ?? '').trim();
    final previousImageUrl = (previous.imageUrl ?? '').trim();

    return nextItem.name != previous.name ||
        nextItem.categoryId != previous.categoryId ||
        nextItem.price != previous.price ||
        nextItem.isActive != previous.isActive ||
        !listEquals(nextBranchIds, previousBranchIds) ||
        !listEquals(nextModifierGroupIds, previousModifierGroupIds) ||
        _selectedImageBytes != null ||
        _selectedImagePath != null ||
        nextImageUrl != previousImageUrl;
  }

  String? _resolveBranchContextForSave() {
    if (_selectedBranchIds.isEmpty) return null;
    final branches = ref.read(menuViewModelProvider).branches;
    for (final branch in branches) {
      if (_selectedBranchIds.contains(branch.id)) {
        return branch.id;
      }
    }
    return _selectedBranchIds.first;
  }

  String? _resolveEditItemId() {
    final state = ref.read(menuViewModelProvider);
    final directId = (widget.initialItem?.id ?? '').trim();
    if (directId.isNotEmpty) return directId;

    final initial = widget.initialItem;
    if (initial == null) return null;

    for (final detail in state.detailByItemId.values) {
      final candidate = detail.item;
      if (candidate.name == initial.name &&
          candidate.categoryId == initial.categoryId &&
          candidate.price == initial.price) {
        final candidateId = candidate.id.trim();
        if (candidateId.isNotEmpty) return candidateId;
      }
    }

    for (final candidate in state.allItems) {
      if (candidate.name == initial.name &&
          candidate.categoryId == initial.categoryId &&
          candidate.price == initial.price) {
        final candidateId = candidate.id.trim();
        if (candidateId.isNotEmpty) return candidateId;
      }
    }

    return null;
  }

  @override
  void dispose() {
    for (final row in _compositionRows) {
      row.dispose();
    }
    for (final rows in _modifierEffectRowsByOptionId.values) {
      for (final row in rows) {
        row.dispose();
      }
    }
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}

class _MenuSectionCard extends StatelessWidget {
  const _MenuSectionCard({
    required this.title,
    this.description,
    this.headerAction,
    required this.children,
  });

  final String title;
  final String? description;
  final Widget? headerAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compactHeader = constraints.maxWidth < 640;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (headerAction == null)
                  _SectionHeaderText(title: title, description: description)
                else if (compactHeader) ...[
                  _SectionHeaderText(title: title, description: description),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: headerAction!),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SectionHeaderText(
                          title: title,
                          description: description,
                        ),
                      ),
                      const SizedBox(width: 12),
                      headerAction!,
                    ],
                  ),
                const SizedBox(height: 16),
                ...children,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionHeaderText extends StatelessWidget {
  const _SectionHeaderText({required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(description!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _SectionHeaderButton extends StatelessWidget {
  const _SectionHeaderButton({
    required this.label,
    required this.onPressed,
    this.showAddIcon = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool showAddIcon;

  @override
  Widget build(BuildContext context) {
    return MenuSectionActionButton(
      label: label,
      onPressed: onPressed,
      showAddIcon: showAddIcon,
    );
  }
}

class _SectionSpacer extends StatelessWidget {
  const _SectionSpacer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 16), child: child);
  }
}

class _MenuActionRow extends StatelessWidget {
  const _MenuActionRow({
    required this.isView,
    required this.isActive,
    required this.isSaving,
    required this.isCreate,
    required this.onCancel,
    required this.onSave,
    required this.onEdit,
    required this.onToggleActive,
  });

  final bool isView;
  final bool isActive;
  final bool isSaving;
  final bool isCreate;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final cancelStyle = AppTheme.cancelActionButtonStyle;
    final saveStyle = FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );

    if (isView) {
      final primaryStyle = FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      );
      final whiteActionStyle = AppTheme.cancelActionButtonStyle;

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 160,
            child: FilledButton(
              style: whiteActionStyle,
              onPressed: isSaving ? null : onToggleActive,
              child: Text(isActive ? 'Archive' : 'Restore'),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: FilledButton.icon(
              style: primaryStyle,
              onPressed: isSaving ? null : onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 140,
          child: FilledButton(
            style: cancelStyle,
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 160,
          child: FilledButton(
            style: saveStyle,
            onPressed: isSaving ? null : onSave,
            child: Text(isCreate ? 'Save item' : 'Save'),
          ),
        ),
      ],
    );
  }
}

class _TwoDecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (text.indexOf('.') != text.lastIndexOf('.')) {
      return oldValue;
    }
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 2) return oldValue;
      if (parts[1].length > 2) return oldValue;
    }
    return newValue;
  }
}
