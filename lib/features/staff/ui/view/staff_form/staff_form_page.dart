// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:modular_pos/core/logging/app_log.dart';
// import 'package:modular_pos/core/routing/app_router.dart';
// import 'package:modular_pos/features/staff/ui/widgets/form_dropdown_field.dart';
// import 'package:modular_pos/features/staff/ui/widgets/form_text_field.dart';
// import 'package:modular_pos/features/staff/ui/widgets/custom_cupertino_list_tile.dart';
// import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
// import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_form_actions.dart';
// import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_profile_avatar.dart';
// import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_schedule_section.dart';
// import 'package:modular_pos/features/staff/ui/viewmodels/staff_management_store.dart';
// import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

// class StaffFormView extends ConsumerStatefulWidget {
//   const StaffFormView({super.key, this.staff, this.branchId});

//   final Staff? staff;
//   final String? branchId;

//   @override
//   ConsumerState<StaffFormView> createState() => _StaffFormViewState();
// }

// class _StaffFormViewState extends ConsumerState<StaffFormView> {
//   final _formKey = GlobalKey<FormState>();
//   String? _selectedRole;
//   String? _selectedGender;
//   String? _selectedBranchId;
//   String? _selectedScheduleOption;
//   String? get _selectedBranch {
//     if (_selectedBranchId == null) return null;
//     final branches = ref.read(loginControllerProvider).user?.branches ?? [];
//     final matchingBranches = branches.where(
//       (b) => (b.branchId.isNotEmpty ? b.branchId : b.id) == _selectedBranchId,
//     );
//     if (matchingBranches.isNotEmpty) {
//       return matchingBranches.first.name;
//     } else {
//       return null;
//     }
//   }

//   // State for the multi-select working days
//   final List<String> _allDays = const [
//     'Monday',
//     'Tuesday',
//     'Wednesday',
//     'Thursday',
//     'Friday',
//     'Saturday',
//     'Sunday',
//   ];
//   Set<String> _selectedWorkingDays = {};
//   // State for working hours
//   TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
//   TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
//   // State for different hours per day
//   String? _expandedDay; // Tracks which day's time picker is open
//   final Map<String, (TimeOfDay, TimeOfDay)> _customHours = {
//     for (var day in const [
//       'Monday',
//       'Tuesday',
//       'Wednesday',
//       'Thursday',
//       'Friday',
//       'Saturday',
//       'Sunday',
//     ])
//       day: (
//         const TimeOfDay(hour: 9, minute: 0),
//         const TimeOfDay(hour: 17, minute: 0),
//       ),
//   };
//   bool _isSubmitting = false;
//   bool _isActive = true;

//   // Controllers for text fields
//   final TextEditingController _userNameController = TextEditingController();
//   final TextEditingController _phoneNumberController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();

//   bool get _isFormValid {
//     return _userNameController.text.isNotEmpty &&
//         _selectedGender != null &&
//         _phoneNumberController.text.isNotEmpty &&
//         _emailController.text.isNotEmpty &&
//         (_isEditing || _passwordController.text.isNotEmpty) &&
//         _selectedRole != null &&
//         _selectedBranchId != null;
//   }

//   bool get _isEditing => widget.staff != null;

//   @override
//   void initState() {
//     super.initState();
//     if (_isEditing) {
//       final staff = widget.staff!;
//       _userNameController.text = staff.userName;
//       _phoneNumberController.text = staff.phoneNumber;
//       _emailController.text = staff.email;
//       _selectedGender = staff.gender;
//       _selectedRole = staff.role;
//       _selectedBranchId = staff.branchId;
//       _selectedScheduleOption = staff.scheduleOption ?? 'same_hours';
//       _isActive = staff.isActive;
//       _selectedWorkingDays = staff.workingDays ?? {};
//       _startTime = staff.startTime ?? const TimeOfDay(hour: 9, minute: 0);
//       _endTime = staff.endTime ?? const TimeOfDay(hour: 17, minute: 0);
//     } else {
//       // For creation, set branch from passed branchId
//       _selectedBranchId = widget.branchId;
//     }
//   }

//   @override
//   void dispose() {
//     _userNameController.dispose();
//     _phoneNumberController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Using Material Scaffold for now to easily contain the form body
//     // with padding and scrolling. Can be swapped for CupertinoPageScaffold.
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => context.pop(),
//         ),
//         title: Text(_isEditing ? 'Edit Staff' : 'Add New Staff'),
//       ),
//       // Dispose controllers when the widget is removed from the widget tree
//       // @override
//       // void dispose() {
//       //   _userNameController.dispose();
//       //   _phoneNumberController.dispose();
//       //   _emailController.dispose();
//       //   super.dispose();
//       // }
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Per Figma: Upload profile
//               const StaffProfileAvatar(),
//               const SizedBox(height: 24),
//               // Per request: Stacked form layout
//               FormTextField(
//                 label: 'User Name',
//                 placeholder: 'e.g., Preap Sovath',
//                 controller: _userNameController,
//                 maxLength: 50,
//                 validator: (value) {
//                   if (value!.isEmpty) {
//                     return 'Please enter user name';
//                   }
//                   if (value.length > 50) {
//                     return 'Name must be 50 characters or less';
//                   }
//                   if (!value.contains(' ')) {
//                     return 'Please enter both first and last name';
//                   }
//                   if (value.contains('\n')) {
//                     return 'Name must be on one line only';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),
//               FormDropdownField(
//                 label: 'Gender',
//                 placeholder: 'Select Gender',
//                 value: _selectedGender,
//                 items: const ['Male', 'Female'],
//                 validator: (value) =>
//                     value == null ? 'Please select gender' : null,
//                 onSelected: (value) {
//                   setState(() {
//                     _selectedGender = value;
//                   });
//                 },
//               ),
//               const SizedBox(height: 12),
//               FormTextField(
//                 label: 'Phone Number',
//                 placeholder: 'e.g., 012345678',
//                 keyboardType: TextInputType.phone,
//                 controller: _phoneNumberController,
//                 maxLength: 15,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.allow(RegExp(r'[\d\+]')),
//                 ],
//                 validator: (value) {
//                   if (value!.isEmpty) {
//                     return 'Please enter phone number';
//                   }
//                   if (value.length > 15) {
//                     return 'Phone number must be 15 characters or less';
//                   }
//                   if (!_isValidPhoneNumber(value)) {
//                     return 'Enter a valid phone number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),
//               FormTextField(
//                 label: 'Email',
//                 placeholder: 'e.g., user@gmail.com',
//                 keyboardType: TextInputType.emailAddress,
//                 controller: _emailController,
//                 maxLength: 100,
//                 validator: (value) {
//                   if (value!.isEmpty) {
//                     return 'Please enter email address';
//                   }
//                   if (value.length > 100) {
//                     return 'Email must be 100 characters or less';
//                   }
//                   if (!_isValidEmail(value)) {
//                     return 'Enter a valid email address';
//                   }
//                   return null;
//                 },
//               ),
//               if (!_isEditing) ...[
//                 const SizedBox(height: 12),
//                 FormTextField(
//                   label: 'Password',
//                   placeholder: 'Enter one-time password',
//                   obscureText: true,
//                   controller: _passwordController,
//                   maxLength: 50,
//                   validator: (value) => value!.isEmpty
//                       ? 'Please enter password'
//                       : value.length > 50
//                       ? 'Password must be 50 characters or less'
//                       : null,
//                 ),
//               ],
//               const SizedBox(height: 16),
//               // Per request: Role and Branch dropdowns side-by-side
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Flexible(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         FormDropdownField(
//                           label: 'Assign Role',
//                           placeholder: 'Select Role',
//                           value: _selectedRole,
//                           validator: (value) =>
//                               value == null ? 'Please select a role' : null,
//                           items: const ['Manager', 'Cashier'],
//                           onSelected: (value) {
//                             setState(() => _selectedRole = value);
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         FormDropdownField(
//                           label: 'Assign Branch',
//                           placeholder: 'Select Branch',
//                           value: _selectedBranch,
//                           validator: (value) =>
//                               value == null ? 'Please select a branch' : null,
//                           items:
//                               ref
//                                   .watch(loginControllerProvider)
//                                   .user
//                                   ?.branches
//                                   .map((b) => b.name)
//                                   .toList() ??
//                               [],
//                           onSelected: (value) {
//                             setState(() {
//                               // Find the corresponding ID
//                               final branches =
//                                   ref
//                                       .read(loginControllerProvider)
//                                       .user
//                                       ?.branches ??
//                                   [];
//                               final matchingBranches = branches.where(
//                                 (b) => b.name == value,
//                               );
//                               if (matchingBranches.isNotEmpty) {
//                                 _selectedBranchId =
//                                     matchingBranches.first.branchId.isNotEmpty
//                                     ? matchingBranches.first.branchId
//                                     : matchingBranches.first.id;
//                               }
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               StaffScheduleSection(
//                 selectedScheduleOption: _selectedScheduleOption,
//                 onScheduleOptionChanged: (value) =>
//                     setState(() => _selectedScheduleOption = value),
//                 allDays: _allDays,
//                 selectedWorkingDays: _selectedWorkingDays,
//                 onWorkingDaysChanged: (newSelectedDays) =>
//                     setState(() => _selectedWorkingDays = newSelectedDays),
//                 startTime: _startTime,
//                 onStartTimeChanged: (newTime) =>
//                     setState(() => _startTime = newTime),
//                 endTime: _endTime,
//                 onEndTimeChanged: (newTime) =>
//                     setState(() => _endTime = newTime),
//                 expandedDay: _expandedDay,
//                 onExpandedDayChanged: (day) =>
//                     setState(() => _expandedDay = day),
//                 customHours: _customHours,
//                 onCustomHoursChanged: (day, start, end) =>
//                     setState(() => _customHours[day] = (start, end)),
//               ),
//               const SizedBox(height: 16),
//               // Custom List Tile for the Switch
//               CustomCupertinoListTile(
//                 title: const Text('Set Active'),
//                 trailing: CupertinoSwitch(
//                   value: _isActive,
//                   onChanged: (bool value) => setState(() => _isActive = value),
//                   activeTrackColor: Theme.of(context).colorScheme.primary,
//                 ),
//               ),
//               const SizedBox(height: 32),
//               StaffFormActions(
//                 isEditing: _isEditing,
//                 onCancel: () async => context.pop(),
//                 onSubmit: _submit,
//                 isSubmitting: _isSubmitting,
//                 isFormValid: _isFormValid,
//               ),
//               const SizedBox(
//                 height: 150,
//               ), // Add space at the bottom of the form
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate() || _isSubmitting) {
//       return;
//     }

//     setState(() => _isSubmitting = true);

//     final newStaff = Staff(
//       userName: _userNameController.text,
//       gender: _selectedGender,
//       phoneNumber: _phoneNumberController.text,
//       email: _emailController.text,
//       role: _selectedRole,
//       branch: _selectedBranch,
//       branchId: _selectedBranchId,
//       scheduleOption: _selectedScheduleOption ?? 'same_hours',
//       isActive: _isActive,
//       workingDays: (_selectedScheduleOption ?? 'same_hours') == 'same_hours'
//           ? _selectedWorkingDays
//           : null,
//       startTime: (_selectedScheduleOption ?? 'same_hours') == 'same_hours'
//           ? _startTime
//           : null,
//       endTime: (_selectedScheduleOption ?? 'same_hours') == 'same_hours'
//           ? _endTime
//           : null,
//       customHours:
//           (_selectedScheduleOption ?? 'different_hours') == 'different_hours'
//           ? _customHours
//           : null,
//       password: !_isEditing ? _passwordController.text : null,
//     );

//     try {
//       if (_isEditing) {
//         // TODO: Implement update API call
//         // For now, simulate success
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Staff updated successfully')),
//         );
//         context.go(AppRoute.staff.path);
//       } else {
//         // For creation, use the store
//         final store = ref.read(staffManagementStoreProvider.notifier);
//         await store.createInvite(newStaff);
//         // On success, navigate back to staff list
//         if (mounted) {
//           context.go(AppRoute.staff.path);
//         }
//       }
//     } catch (e) {
//       // Handle error
//       AppLog.e('Failed to create staff: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Failed to create staff')));
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isSubmitting = false);
//       }
//     }
//   }

//   bool _isValidPhoneNumber(String raw) {
//     var value = raw.trim();
//     if (value.isEmpty) return false;
//     if (value.startsWith('+')) {
//       value = value.substring(1);
//     }
//     if (value.isEmpty) return false;
//     final allDigits = value.codeUnits.every((c) => c >= 48 && c <= 57);
//     if (!allDigits) return false;
//     return value.length >= 7 && value.length <= 15;
//   }

//   bool _isValidEmail(String raw) {
//     final value = raw.trim();
//     if (value.isEmpty) return false;
//     if (value.contains(' ')) return false;
//     final at = value.indexOf('@');
//     if (at <= 0) return false;
//     final dot = value.lastIndexOf('.');
//     if (dot <= at + 1) return false;
//     if (dot >= value.length - 1) return false;
//     return true;
//   }
// }
