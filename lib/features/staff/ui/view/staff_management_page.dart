import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_profile_avatar.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_schedule_section.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_management_store.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_list_store.dart';
import 'package:modular_pos/features/staff/ui/widgets/custom_cupertino_list_tile.dart';
import 'package:modular_pos/features/staff/ui/widgets/form_dropdown_field.dart';
import 'package:modular_pos/features/staff/ui/widgets/form_text_field.dart';
import 'package:modular_pos/features/staff/ui/widgets/staff_schedule_table.dart';

class StaffManagementPage extends ConsumerStatefulWidget {
  const StaffManagementPage({
    super.key,
    this.initialStaff,
    this.initialBranchId,
    this.staffId,
  });

  final Staff? initialStaff;
  final String? initialBranchId;
  final String? staffId;

  @override
  ConsumerState<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _userNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Local State for Form Data
  String? _selectedGender;
  String? _selectedRole;
  String? _selectedBranchId;
  String? _selectedScheduleOption;
  bool _isActive = true;
  bool _hasInitialized = false;

  // Schedule State
  final List<String> _allDays = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  Set<String> _selectedWorkingDays = {};
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  String? _expandedDay;
  final Map<String, (TimeOfDay, TimeOfDay)> _customHours = {
    for (var day in const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ])
      day: (
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 17, minute: 0),
      ),
  };

  @override
  void initState() {
    super.initState();
    // Initialize controller state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Strategy: Use initialStaff if provided.
      // If null (e.g. refresh/resize), try to find by staffId in the store.
      Staff? staff = widget.initialStaff;
      
      if (staff == null && widget.staffId != null) {
        final listAsync = ref.read(StaffListAsyncNotifier.provider);
        // Only if we have data loaded
        if (listAsync.hasValue) {
           final list = listAsync.value?.staffList ?? [];
           try {
             staff = list.firstWhere((s) => s.id == widget.staffId);
           } catch (_) {
             // Staff not found in local list
           }
        }
      }

      ref
          .read(staffManagementControllerProvider.notifier)
          .initialize(staff, widget.initialBranchId);
      
      if (!mounted) return;
      
      // Use state.initialStaff after initialization, not widget.initialStaff
      final state = ref.read(staffManagementControllerProvider);
      _populateForm(
        state.initialStaff ??
            Staff(
              userName: '',
              phoneNumber: '',
              email: '',
              isActive: true,
              branchId: widget.initialBranchId,
            ),
      );
      
      if (mounted) {
        setState(() {
          _hasInitialized = true;
        });
      }
    });
  }

  void _populateForm(Staff? staff) {
    if (staff == null) return; // Guard against null
    
    _userNameController.text = staff.userName;
    _phoneNumberController.text = staff.phoneNumber;
    _emailController.text = staff.email;
    _selectedGender = staff.gender;
    _selectedRole = staff.role;
    _selectedBranchId = staff.branchId;
    _selectedScheduleOption = staff.scheduleOption ?? 'same_hours';
    _isActive = staff.isActive;

    if (staff.workingDays != null) {
      _selectedWorkingDays = Set.from(staff.workingDays!);
    }
    if (staff.startTime != null) _startTime = staff.startTime!;
    if (staff.endTime != null) _endTime = staff.endTime!;
    if (staff.customHours != null) {
      _customHours.addAll(staff.customHours!);
    }
  }

  String? get _selectedBranchName {
    if (_selectedBranchId == null) return null;
    final branches = ref.read(loginControllerProvider).user?.branches ?? [];
    final match = branches.where(
      (b) => (b.branchId.isNotEmpty ? b.branchId : b.id) == _selectedBranchId,
    );
    return match.isNotEmpty ? match.first.name : null;
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isCreateMode =>
      ref.read(staffManagementControllerProvider).mode ==
      StaffManagementMode.create;
  bool get _isViewMode =>
      ref.watch(staffManagementControllerProvider).mode ==
      StaffManagementMode.view;
  bool get _isEditMode =>
      ref.read(staffManagementControllerProvider).mode ==
      StaffManagementMode.edit;

  @override
  Widget build(BuildContext context) {
    // Wait for initialization
    if (!_hasInitialized) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(staffManagementControllerProvider);
    final isReadOnly = state.mode == StaffManagementMode.view;
    final isMobile = AppBreakpoints.isSmall(MediaQuery.of(context).size.width);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(
          state.mode == StaffManagementMode.create
              ? 'Add New Staff'
              : state.mode == StaffManagementMode.edit
              ? 'Edit Staff'
              : 'Staff Details',
        ),
        actions: [
          if (state.mode == StaffManagementMode.view)
            TextButton(
              onPressed:
                  () => ref
                      .read(staffManagementControllerProvider.notifier)
                      .toggleEditMode(),
              child: const Text('Edit'),
            ),
        ],
      ),
      body:
          state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.red.shade50,
                          child: Text(
                            state.error!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Profile Picture
                      const Center(child: StaffProfileAvatar()),
                      const SizedBox(height: 24),

                      // Form Fields
                      if (isMobile) ..._buildFormFields(isReadOnly, isMobile) else
                        // Tablet/Desktop Layout
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: _buildLeftColumnFields(
                                  isReadOnly,
                                  isMobile,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: _buildRightColumnFields(
                                  isReadOnly,
                                  isMobile,
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (isReadOnly) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        if (state.initialStaff?.shiftSchedule != null)
                          StaffScheduleTable(
                            schedule: state.initialStaff!.shiftSchedule!,
                          ),
                      ],

                      const SizedBox(height: 32),

                      // Actions
                      if (!isReadOnly)
                        Row(
                          children: [
                            if (_isEditMode)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      () => ref
                                          .read(
                                            staffManagementControllerProvider
                                                .notifier,
                                          )
                                          .toggleEditMode(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                            if (_isEditMode) const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isFormValid() ? _submit : null,
                                child: Text(
                                  _isCreateMode ? 'Create Staff' : 'Save Changes',
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
    );
  }

  List<Widget> _buildFormFields(bool isReadOnly, bool isMobile) {
    return [
      ..._buildLeftColumnFields(isReadOnly, isMobile),
      ..._buildRightColumnFields(isReadOnly, isMobile),
    ];
  }

  List<Widget> _buildLeftColumnFields(bool isReadOnly, bool isMobile) {
    return [
      FormTextField(
        label: 'User Name',
        placeholder: 'e.g., Preap Sovath',
        controller: _userNameController,
        readOnly: isReadOnly,
        maxLength: 50,
        validator:
            (v) =>
                v!.isEmpty
                    ? 'Required'
                    : !v.contains(' ')
                    ? 'Enter full name'
                    : null,
      ),
      const SizedBox(height: 12),
      FormDropdownField(
        label: 'Gender',
        placeholder: 'Select Gender',
        value: _selectedGender,
        items: const ['Male', 'Female'],
        enabled: !isReadOnly,
        onSelected: (val) => setState(() => _selectedGender = val),
        validator: (v) => v == null ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      FormTextField(
        label: 'Phone Number',
        placeholder: 'e.g., 012345678',
        keyboardType: TextInputType.phone,
        controller: _phoneNumberController,
        readOnly: isReadOnly,
        maxLength: 15,
        validator:
            (v) =>
                v!.isEmpty
                    ? 'Required'
                    : v.length < 7
                    ? 'Invalid phone'
                    : null,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+]'))],
      ),
      const SizedBox(height: 12),
      FormTextField(
        label: 'Email',
        placeholder: 'e.g., user@gmail.com',
        keyboardType: TextInputType.emailAddress,
        controller: _emailController,
        readOnly: isReadOnly,
        maxLength: 100,
        validator:
            (v) =>
                v!.isEmpty
                    ? 'Required'
                    : !v.contains('@')
                    ? 'Invalid email'
                    : null,
      ),
      if (_isCreateMode) ...[
        const SizedBox(height: 12),
        FormTextField(
          label: 'Password',
          placeholder: 'Enter one-time password',
          obscureText: true,
          controller: _passwordController,
          maxLength: 50,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
      ],
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildRightColumnFields(bool isReadOnly, bool isMobile) {
    return [
      FormDropdownField(
        label: 'Assign Role',
        placeholder: 'Select Role',
        value: _selectedRole,
        items: const ['Manager', 'Cashier'],
        enabled: !isReadOnly,
        onSelected: (val) => setState(() => _selectedRole = val),
        validator: (v) => v == null ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      FormDropdownField(
        label: 'Assign Branch',
        placeholder: 'Select Branch',
        value: _selectedBranchName,
        items:
            ref
                .watch(loginControllerProvider)
                .user
                ?.branches
                .map((b) => b.name)
                .toList() ??
            [],
        enabled: !isReadOnly,
        onSelected: (val) {
          final branches =
              ref.read(loginControllerProvider).user?.branches ?? [];
          final match = branches.where((b) => b.name == val);
          if (match.isNotEmpty) {
            setState(
              () =>
                  _selectedBranchId =
                      match.first.branchId.isNotEmpty
                          ? match.first.branchId
                          : match.first.id,
            );
          }
        },
        validator: (v) => v == null ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      if (!isReadOnly) ...[
        StaffScheduleSection(
          selectedScheduleOption: _selectedScheduleOption,
          onScheduleOptionChanged:
              (v) => setState(() => _selectedScheduleOption = v),
          allDays: _allDays,
          selectedWorkingDays: _selectedWorkingDays,
          onWorkingDaysChanged: (v) => setState(() => _selectedWorkingDays = v),
          startTime: _startTime,
          onStartTimeChanged: (v) => setState(() => _startTime = v),
          endTime: _endTime,
          onEndTimeChanged: (v) => setState(() => _endTime = v),
          expandedDay: _expandedDay,
          onExpandedDayChanged: (v) => setState(() => _expandedDay = v),
          customHours: _customHours,
          onCustomHoursChanged:
              (d, s, e) => setState(() => _customHours[d] = (s, e)),
        ),
        const SizedBox(height: 16),
        CustomCupertinoListTile(
          title: const Text('Set Active'),
          trailing: CupertinoSwitch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    ];
  }


  bool _isFormValid() {
    // Check all required fields
    if (_userNameController.text.trim().isEmpty) return false;
    if (_phoneNumberController.text.trim().isEmpty) return false;
    if (_emailController.text.trim().isEmpty) return false;
    if (_selectedGender == null) return false;
    if (_selectedRole == null) return false;
    if (_selectedBranchId == null) return false;
    if (_isCreateMode && _passwordController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Get the staff ID from state instead of widget
    final state = ref.read(staffManagementControllerProvider);
    
    final staff = Staff(
      id: state.initialStaff?.id, // Use state.initialStaff instead of widget.initialStaff
      userName: _userNameController.text,
      gender: _selectedGender,
      phoneNumber: _phoneNumberController.text,
      email: _emailController.text,
      role: _selectedRole,
      branchId: _selectedBranchId,
      isActive: _isActive,
      password: _isCreateMode ? _passwordController.text : null,
      // Pass schedule data
      scheduleOption: _selectedScheduleOption,
      workingDays:
          _selectedScheduleOption == 'same_hours' ? _selectedWorkingDays : null,
      startTime: _selectedScheduleOption == 'same_hours' ? _startTime : null,
      endTime: _selectedScheduleOption == 'same_hours' ? _endTime : null,
      customHours:
          _selectedScheduleOption == 'different_hours' ? _customHours : null,
    );

    final success = await ref
        .read(staffManagementControllerProvider.notifier)
        .submit(staff);

    if (!mounted) return;

    if (success) {
      // Show success message only for edit mode
      if (_isEditMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      context.pop(true); // Return the updated staff object
    }
  }
}