import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/features/staff/ui/widgets/form_dropdown_field.dart';
import 'package:modular_pos/features/staff/ui/widgets/form_text_field.dart';
import 'package:modular_pos/features/staff/ui/widgets/custom_cupertino_list_tile.dart';
import 'package:modular_pos/features/staff/ui/widgets/working_days_dropdown.dart';
import 'package:modular_pos/features/staff/ui/widgets/time_picker_dropdown.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';

class StaffFormView extends StatefulWidget {
  const StaffFormView({super.key, this.staff});

  final Staff? staff;

  @override
  State<StaffFormView> createState() => _StaffFormViewState();
}

class _StaffFormViewState extends State<StaffFormView> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;
  String? _selectedGender;
  String? _selectedBranch;
  String? _selectedScheduleOption;
  // State for the multi-select working days
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
  // State for working hours
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  // State for different hours per day
  String? _expandedDay; // Tracks which day's time picker is open
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
  bool _isActive = true;

  // Controllers for text fields
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool get _isEditing => widget.staff != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final staff = widget.staff!;
      _userNameController.text = staff.userName;
      _phoneNumberController.text = staff.phoneNumber;
      _emailController.text = staff.email;
      _selectedGender = staff.gender;
      _selectedRole = staff.role;
      _selectedBranch = staff.branch;
      _selectedScheduleOption = staff.scheduleOption ?? 'same_hours';
      _isActive = staff.isActive;
      _selectedWorkingDays = staff.workingDays ?? {};
      _startTime = staff.startTime ?? const TimeOfDay(hour: 9, minute: 0);
      _endTime = staff.endTime ?? const TimeOfDay(hour: 17, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using Material Scaffold for now to easily contain the form body
    // with padding and scrolling. Can be swapped for CupertinoPageScaffold.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEditing ? 'Edit Staff' : 'Add New Staff'),
      ),
      // Dispose controllers when the widget is removed from the widget tree
      // @override
      // void dispose() {
      //   _userNameController.dispose();
      //   _phoneNumberController.dispose();
      //   _emailController.dispose();
      //   super.dispose();
      // }
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Per Figma: Upload profile
              Center(
                child: Stack(
                  children: [
                    const CircleAvatar(
                      radius: 60, // Made bigger
                      backgroundColor: Colors.black12,
                      child: Icon(
                        CupertinoIcons.person_fill,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white, // Background is white
                        child: Icon(
                          CupertinoIcons.camera_fill,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Per request: Stacked form layout
              FormTextField(
                label: 'User Name',
                placeholder: 'e.g., Preap Sovath',
                controller: _userNameController,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter user name' : null,
              ),
              const SizedBox(height: 12),
              FormDropdownField(
                label: 'Gender',
                placeholder: 'Select Gender',
                value: _selectedGender,
                items: const ['Male', 'Female'],
                validator: (value) =>
                    value == null ? 'Please select gender' : null,
                onSelected: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              FormTextField(
                label: 'Phone Number',
                placeholder: 'e.g., 012345678',
                keyboardType: TextInputType.phone,
                controller: _phoneNumberController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (!_isValidPhoneNumber(value)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              FormTextField(
                label: 'Email',
                placeholder: 'e.g., user@gmail.com',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!_isValidEmail(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Per request: Role and Branch dropdowns side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormDropdownField(
                          label: 'Assign Role',
                          placeholder: 'Select Role',
                          value: _selectedRole,
                          validator: (value) =>
                              value == null ? 'Please select a role' : null,
                          items: const ['Manager', 'Cashier'],
                          onSelected: (value) {
                            setState(() => _selectedRole = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormDropdownField(
                          label: 'Assign Branch',
                          placeholder: 'Select Branch',
                          value: _selectedBranch,
                          validator: (value) =>
                              value == null ? 'Please select a branch' : null,
                          items: const ['Main Branch', 'Second Branch'],
                          onSelected: (value) {
                            setState(() => _selectedBranch = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Schedule Type'),
              const SizedBox(height: 8),
              // Custom List Tile for radio selection (Same Hours) - Now a reusable widget
              CustomCupertinoListTile(
                title: const Text('Apply same hours to all days'),
                leading: Icon(
                  _selectedScheduleOption == 'same_hours'
                      ? CupertinoIcons.circle_filled
                      : CupertinoIcons.circle,
                  color: _selectedScheduleOption == 'same_hours'
                      ? Theme.of(context).colorScheme.primary
                      : CupertinoColors.inactiveGray,
                ),
                onTap: () {
                  setState(() {
                    _selectedScheduleOption = 'same_hours';
                  });
                },
              ),
              // Custom List Tile for radio selection (Different Hours) - Now a reusable widget
              CustomCupertinoListTile(
                title: const Text('Set different hours per day'),
                leading: Icon(
                  _selectedScheduleOption == 'different_hours'
                      ? CupertinoIcons.circle_filled
                      : CupertinoIcons.circle,
                  color: _selectedScheduleOption == 'different_hours'
                      ? Theme.of(context).colorScheme.primary
                      : CupertinoColors.inactiveGray,
                ),
                onTap: () {
                  setState(() {
                    _selectedScheduleOption = 'different_hours';
                  });
                },
              ),
              // Per request: Show different UI based on selection, inside the section
              if (_selectedScheduleOption == 'same_hours')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Working Days',
                    ), // This section uses the WorkingDaysDropdown widget
                    const SizedBox(height: 8),
                    WorkingDaysDropdown(
                      selectedDays: _selectedWorkingDays,
                      onChanged: (newSelectedDays) {
                        setState(() {
                          _selectedWorkingDays = newSelectedDays;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Per request: Implement "from" and "to" time selectors
                    const Text('Working Hours'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'from',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              TimePickerDropdown(
                                initialTime: _startTime,
                                onTimeChanged: (newTime) =>
                                    setState(() => _startTime = newTime),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'to',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              TimePickerDropdown(
                                initialTime: _endTime,
                                onTimeChanged: (newTime) =>
                                    setState(() => _endTime = newTime),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              // Per request: UI for "Set different hours per day"
              if (_selectedScheduleOption == 'different_hours')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Working Days',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Select day',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._allDays.map((day) {
                      final bool isExpanded = _expandedDay == day;
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedDay = isExpanded ? null : day;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    day,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? CupertinoIcons.circle_filled
                                        : CupertinoIcons.circle,
                                    color: isExpanded
                                        ? Theme.of(context).colorScheme.primary
                                        : CupertinoColors.inactiveGray,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                left: 8,
                                right: 8,
                                bottom: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'from',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TimePickerDropdown(
                                          initialTime: _customHours[day]!.$1,
                                          onTimeChanged: (newTime) {
                                            setState(() {
                                              _customHours[day] = (
                                                newTime,
                                                _customHours[day]!.$2,
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'to',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TimePickerDropdown(
                                          initialTime: _customHours[day]!.$2,
                                          onTimeChanged: (newTime) {
                                            setState(() {
                                              _customHours[day] = (
                                                _customHours[day]!.$1,
                                                newTime,
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 16),
              // Custom List Tile for the Switch
              CustomCupertinoListTile(
                title: const Text('Set Active'),
                trailing: CupertinoSwitch(
                  value: _isActive,
                  onChanged: (bool value) => setState(() => _isActive = value),
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              // Per request: Add Cancel and Add New Staff buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    color: Colors.grey.shade200,
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(_isEditing ? 'Save Changes' : 'Add New Staff'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Form is valid, create a Staff object
                        final newStaff = Staff(
                          userName: _userNameController.text,
                          gender: _selectedGender,
                          phoneNumber: _phoneNumberController.text,
                          email: _emailController.text,
                          role: _selectedRole,
                          branch: _selectedBranch,
                          scheduleOption: _selectedScheduleOption,
                          isActive: _isActive,
                          workingDays: _selectedScheduleOption == 'same_hours'
                              ? _selectedWorkingDays
                              : null,
                          startTime: _selectedScheduleOption == 'same_hours'
                              ? _startTime
                              : null,
                          endTime: _selectedScheduleOption == 'same_hours'
                              ? _endTime
                              : null,
                          customHours:
                              _selectedScheduleOption == 'different_hours'
                              ? _customHours
                              : null,
                        );

                        // Pop the screen and return the new staff object
                        context.pop(newStaff);
                      } else {
                        // Form is invalid, show an error or scroll to first error
                        AppLog.d('Staff form validation failed');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 150,
              ), // Add space at the bottom of the form
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidPhoneNumber(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return false;
    if (value.startsWith('+')) {
      value = value.substring(1);
    }
    if (value.isEmpty) return false;
    final allDigits = value.codeUnits.every((c) => c >= 48 && c <= 57);
    if (!allDigits) return false;
    return value.length >= 7 && value.length <= 15;
  }

  bool _isValidEmail(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    if (value.contains(' ')) return false;
    final at = value.indexOf('@');
    if (at <= 0) return false;
    final dot = value.lastIndexOf('.');
    if (dot <= at + 1) return false;
    if (dot >= value.length - 1) return false;
    return true;
  }
}
