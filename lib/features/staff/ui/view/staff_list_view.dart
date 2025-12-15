import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/features/staff/ui/widgets/app_filter_dropdown.dart';
import 'package:modular_pos/core/widgets/app_search_add_bar.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/ui/widgets/staff_list_card.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form_view.dart';
import 'package:modular_pos/features/staff/ui/view/staff_detail_view.dart';

class StaffListView extends StatefulWidget {
  const StaffListView({super.key});

  @override
  State<StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends State<StaffListView> {
  String? _selectedBranch;
  String? _selectedRole;
  String? _selectedStatus;

  // Placeholder list of staff members
  final List<Staff> _staffList = [
    Staff(userName: 'John Doe', role: 'Manager',gender: "Male", branch: 'Main Branch', isActive: true, email: 'john@test.com', phoneNumber: '012345678'),
    Staff(userName: 'Jane Smith', role: 'Cashier', gender: "Female", branch: 'Second Branch', isActive: true, email: 'jane@test.com', phoneNumber: '012345456'),
    // Staff(userName: 'Peter Jones', role: 'Cashier', branch: 'Main Branch', isActive: false, email: 'peter@test.com', phoneNumber: '012345789'),
  ];

  final _branchOptions = const ['Main Branch', 'Second Branch'];
  final _roleOptions = const ['Manager', 'Cashier'];
  final _statusOptions = const ['Active', 'Inactive'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Per Figma: Add back button and set title to "Staff"
        // Use context.pop() for go_router compatibility
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Staff'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchAddBar(
              // Use phone number as per modula_capstone_1_scope.md
              searchHint: 'Search',
              onSearchChanged: (value) {
                // TODO: Implement search logic
              },
              onAddPressed: () async {
                if (_staffList.length >= 3) {
                  // Show warning dialog if staff limit is reached
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Staff Limit Reached',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "You've reached the maximum staff allowed in your plan. Upgrade to add more staff.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton(
                                    color: Colors.grey.shade200,
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontSize: 14)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CupertinoButton.filled(
                                    onPressed: () {
                                      // TODO: Implement upgrade plan logic
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Upgrade Plan', style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  // Navigate to the StaffFormView if limit is not reached
                  final newStaff = await Navigator.of(context).push<Staff>(
                    CupertinoPageRoute(builder: (context) => const StaffFormView()),
                  );
                  if (newStaff != null) {
                    setState(() => _staffList.add(newStaff));
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            // Per request: Place dropdowns next to each other
            // Use Wrap to prevent overflow on smaller screens
            Wrap(
              spacing: 12.0, // Horizontal space between children
              runSpacing: 12.0, // Vertical space between lines
              children: [
                AppFilterDropdown<String>(
                  hintText: 'Branch',
                  allText: 'All Branches',
                  items: _branchOptions,
                  value: _selectedBranch,
                  onChanged: (value) {
                    setState(() => _selectedBranch = value);
                    // TODO: Implement branch filter logic
                  },
                ),
                AppFilterDropdown<String>(
                  hintText: 'Role',
                  allText: 'All Roles',
                  items: _roleOptions,
                  value: _selectedRole,
                  onChanged: (value) {
                    setState(() => _selectedRole = value);
                    // TODO: Implement role filter logic
                  },
                ),
                AppFilterDropdown<String>(
                  hintText: 'Status',
                  allText: 'All Status',
                  items: _statusOptions,
                  value: _selectedStatus,
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    // TODO: Implement status filter logic
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Per Figma: Add staff count text
            Text(
              '${_staffList.length} Staff Members (limit 3)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              // TODO: Replace with a BlocBuilder and a real list
              child: ListView.separated(
                // Per Figma: Show 3 items
                itemCount: _staffList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return StaffListCard(
                    staffMember: _staffList[index],
                    onTap: () async {
                      final result = await Navigator.of(context).push<Staff>(
                        CupertinoPageRoute(
                          builder: (context) => StaffDetailView(staff: _staffList[index]),
                        ),
                      );

                      // If the detail/edit screen returned an updated staff member,
                      // update the list.
                      if (result != null) {
                        setState(() {
                          _staffList[index] = result;
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
