import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/theme/app_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_authentication_section.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_basic_info_section.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_mobile_form_section.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_schedule_section.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_list_store.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_management_store.dart';
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
  ConsumerState<StaffManagementPage> createState() =>
      _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Local State for Form Data
  String? _selectedGender;
  String? _selectedRole;
  String? _selectedBranchId;
  String? _selectedScheduleOption;
  bool _isActive = true;
  bool _hasInitialized = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Staff member not found'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              context.pop();
            }
            return;
          }
        }
      }

      ref
          .read(staffManagementControllerProvider.notifier)
          .initialize(staff, widget.initialBranchId);

      if (!mounted) return;

      // Use state.initialStaff after initialization, not widget.initialStaff
      final state = ref.read(staffManagementControllerProvider);

      // Only populate form if we have existing staff (view/edit mode)
      // For create mode, ensure form is clean
      if (state.mode == StaffManagementMode.create) {
        _clearForm();
        // Set default branch if provided
        if (widget.initialBranchId != null) {
          _selectedBranchId = widget.initialBranchId;
        }
      } else if (state.initialStaff != null) {
        _populateForm(state.initialStaff!);
      }

      if (mounted) {
        setState(() {
          _hasInitialized = true;
        });
      }
    });
  }

  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneNumberController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _selectedGender = null;
      _selectedRole = null;
      _selectedBranchId = null;
      _selectedScheduleOption = 'same_hours';
      _isActive = true; // New staff start as Active
      _selectedWorkingDays = {};
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 17, minute: 0);
      _expandedDay = null;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  void _populateForm(Staff? staff) {
    if (staff == null) return; // Guard against null

    // Split userName into first and last name
    final nameParts = staff.userName.split(' ');
    if (nameParts.isNotEmpty) {
      _firstNameController.text = nameParts.first;
      if (nameParts.length > 1) {
        _lastNameController.text = nameParts.sublist(1).join(' ');
      }
    }
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isCreateMode =>
      ref.read(staffManagementControllerProvider).mode ==
      StaffManagementMode.create;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = AppBreakpoints.isSmall(constraints.maxWidth);

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
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 120,
                    child: FilledButton.icon(
                      style: AppTheme.editActionButtonStyle,
                      onPressed: () => ref
                          .read(staffManagementControllerProvider.notifier)
                          .toggleEditMode(),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: SingleChildScrollView(
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

                            // Form Fields
                            if (isMobile)
                              StaffMobileFormSection(
                                firstNameController: _firstNameController,
                                lastNameController: _lastNameController,
                                phoneNumberController: _phoneNumberController,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                confirmPasswordController:
                                    _confirmPasswordController,
                                selectedGender: _selectedGender,
                                onGenderChanged: (val) =>
                                    setState(() => _selectedGender = val),
                                selectedRole: _selectedRole,
                                onRoleChanged: (val) =>
                                    setState(() => _selectedRole = val),
                                selectedBranchName: _selectedBranchName,
                                selectedBranchId: _selectedBranchId,
                                onBranchChanged: (val) =>
                                    setState(() => _selectedBranchId = val),
                                isActive: _isActive,
                                onActiveChanged: (v) =>
                                    setState(() => _isActive = v),
                                selectedScheduleOption: _selectedScheduleOption,
                                onScheduleOptionChanged: (v) =>
                                    setState(() => _selectedScheduleOption = v),
                                allDays: _allDays,
                                selectedWorkingDays: _selectedWorkingDays,
                                onWorkingDaysChanged: (v) =>
                                    setState(() => _selectedWorkingDays = v),
                                startTime: _startTime,
                                onStartTimeChanged: (v) =>
                                    setState(() => _startTime = v),
                                endTime: _endTime,
                                onEndTimeChanged: (v) =>
                                    setState(() => _endTime = v),
                                expandedDay: _expandedDay,
                                onExpandedDayChanged: (v) =>
                                    setState(() => _expandedDay = v),
                                customHours: _customHours,
                                onCustomHoursChanged: (d, s, e) =>
                                    setState(() => _customHours[d] = (s, e)),
                                isReadOnly: isReadOnly,
                                isCreateMode: _isCreateMode,
                                obscurePassword: _obscurePassword,
                                obscureConfirmPassword: _obscureConfirmPassword,
                                onTogglePasswordVisibility: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                onToggleConfirmPasswordVisibility: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              )
                            else
                              // Tablet/Desktop Layout
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Basic Information Section
                                  StaffBasicInfoSection(
                                    firstNameController: _firstNameController,
                                    lastNameController: _lastNameController,
                                    phoneNumberController:
                                        _phoneNumberController,
                                    emailController: _emailController,
                                    selectedGender: _selectedGender,
                                    onGenderChanged: (val) =>
                                        setState(() => _selectedGender = val),
                                    selectedRole: _selectedRole,
                                    onRoleChanged: (val) =>
                                        setState(() => _selectedRole = val),
                                    selectedBranchName: _selectedBranchName,
                                    selectedBranchId: _selectedBranchId,
                                    onBranchChanged: (val) {
                                      final branches =
                                          ref
                                              .read(loginControllerProvider)
                                              .user
                                              ?.branches ??
                                          [];
                                      final match = branches.where(
                                        (b) => b.name == val,
                                      );
                                      if (match.isNotEmpty) {
                                        setState(
                                          () => _selectedBranchId =
                                              match.first.branchId.isNotEmpty
                                              ? match.first.branchId
                                              : match.first.id,
                                        );
                                      }
                                    },
                                    isActive: _isActive,
                                    onActiveChanged: (v) =>
                                        setState(() => _isActive = v),
                                    isReadOnly: isReadOnly,
                                  ),
                                  const SizedBox(height: 24),
                                  // Working Schedule Section
                                  if (!isReadOnly)
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: _buildScheduleSection(
                                          isReadOnly,
                                        ),
                                      ),
                                    ),
                                  if (!isReadOnly) const SizedBox(height: 24),
                                  // Authentication Section (only in edit/create mode)
                                  if (!isReadOnly)
                                    StaffAuthenticationSection(
                                      phoneNumberController:
                                          _phoneNumberController,
                                      passwordController: _passwordController,
                                      confirmPasswordController:
                                          _confirmPasswordController,
                                      isCreateMode: _isCreateMode,
                                      isReadOnly: isReadOnly,
                                      obscurePassword: _obscurePassword,
                                      obscureConfirmPassword:
                                          _obscureConfirmPassword,
                                      onTogglePasswordVisibility: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      onToggleConfirmPasswordVisibility: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                ],
                              ),

                            if (isReadOnly && !isMobile) ...[
                              const SizedBox(height: 24),
                              // Working Schedule Section in view mode (wide screen only)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildScheduleSection(isReadOnly),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Authentication Section in view mode
                              StaffAuthenticationSection(
                                phoneNumberController: _phoneNumberController,
                                passwordController: _passwordController,
                                confirmPasswordController:
                                    _confirmPasswordController,
                                isCreateMode: _isCreateMode,
                                isReadOnly: isReadOnly,
                                obscurePassword: _obscurePassword,
                                obscureConfirmPassword: _obscureConfirmPassword,
                                onTogglePasswordVisibility: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                onToggleConfirmPasswordVisibility: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ],

                            if (isReadOnly && isMobile) ...[
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
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_isEditMode || _isCreateMode)
                                    SizedBox(
                                      width: 120,
                                      child: FilledButton(
                                        style: AppTheme.cancelActionButtonStyle,
                                        onPressed: () {
                                          if (_isEditMode) {
                                            ref
                                                .read(
                                                  staffManagementControllerProvider
                                                      .notifier,
                                                )
                                                .toggleEditMode();
                                          } else {
                                            context.pop();
                                          }
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                  if (_isEditMode || _isCreateMode)
                                    const SizedBox(width: 16),
                                  SizedBox(
                                    width: 150,
                                    child: FilledButton(
                                      style: AppTheme.editActionButtonStyle,
                                      onPressed: _isFormValid()
                                          ? _submit
                                          : null,
                                      child: Text(
                                        _isCreateMode
                                            ? 'Create Staff'
                                            : 'Save Changes',
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
                  ),
                ),
        );
      },
    );
  }

  List<Widget> _buildScheduleSection(bool isReadOnly, {bool isMobile = false}) {
    return [
      if (!isMobile) ...[
        Text(
          'Working Schedule',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Set shifts and working hours for the staff',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
      ],
      StaffScheduleSection(
        isMobile: isMobile,
        isReadOnly: isReadOnly,
        selectedScheduleOption: _selectedScheduleOption,
        onScheduleOptionChanged: (v) =>
            setState(() => _selectedScheduleOption = v),
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
        onCustomHoursChanged: (d, s, e) =>
            setState(() => _customHours[d] = (s, e)),
      ),
    ];
  }

  bool _isFormValid() {
    // Check all required fields
    if (_firstNameController.text.trim().isEmpty) return false;
    if (_lastNameController.text.trim().isEmpty) return false;
    if (_phoneNumberController.text.trim().isEmpty) return false;
    if (_emailController.text.trim().isEmpty) return false;
    if (_selectedGender == null) return false;
    if (_selectedRole == null) return false;
    if (_selectedBranchId == null) return false;
    if (_isCreateMode) {
      if (_passwordController.text.trim().isEmpty) return false;
      if (_confirmPasswordController.text.trim().isEmpty) return false;
      if (_passwordController.text != _confirmPasswordController.text) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Get the staff ID from state instead of widget
    final state = ref.read(staffManagementControllerProvider);

    final staff = Staff(
      id: state
          .initialStaff
          ?.id, // Use state.initialStaff instead of widget.initialStaff
      userName: '${_firstNameController.text} ${_lastNameController.text}'
          .trim(),
      gender: _selectedGender,
      phoneNumber: _phoneNumberController.text,
      email: _emailController.text,
      role: _selectedRole,
      branchId: _selectedBranchId,
      isActive: _isActive,
      password: _isCreateMode ? _passwordController.text : null,
      // Pass schedule data
      scheduleOption: _selectedScheduleOption,
      workingDays: _selectedScheduleOption == 'same_hours'
          ? _selectedWorkingDays
          : null,
      startTime: _selectedScheduleOption == 'same_hours' ? _startTime : null,
      endTime: _selectedScheduleOption == 'same_hours' ? _endTime : null,
      customHours: _selectedScheduleOption == 'different_hours'
          ? _customHours
          : null,
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
