import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/staff/ui/widgets/app_filter_dropdown.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/ui/widgets/staff_list_card.dart';
import 'package:modular_pos/features/staff/data/staff_management_repository.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';
import 'package:modular_pos/features/auth/domain/models/user.dart';

class StaffListView extends ConsumerStatefulWidget {
  const StaffListView({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  ConsumerState<StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends ConsumerState<StaffListView> {
  String? _selectedBranch;
  String? _selectedRole;
  String? _selectedStatus;
  String _searchQuery = '';
  bool _loading = false;
  String? _errorMessage;

  List<Staff> _staffList = [];

  List<String> _branchOptions = const [];
  final _roleOptions = const ['Manager', 'Cashier', 'Admin'];
  final _statusOptions = const ['Active', 'Invited', 'Disabled', 'Archived'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final user = ref.read(loginControllerProvider).user;
    final branches = user?.branches ?? const [];
    final options = branches
        .map((b) => b.name)
        .where((name) => name.isNotEmpty)
        .toList();
    setState(() {
      _branchOptions = options;
      if (user?.role.toLowerCase() != 'admin' && options.isNotEmpty) {
        _selectedBranch = options.first;
      }
    });
    await _loadStaff();
  }

  String? _branchIdForName(String? name) {
    if (name == null) return null;
    final branches =
        ref.read(loginControllerProvider).user?.branches ?? const [];
    final match = branches.firstWhere(
      (b) => b.name == name,
      orElse: () => const UserBranch(id: '', name: '', role: '', active: false),
    );
    if (match.id.isEmpty && match.branchId.isEmpty) return null;
    return match.branchId.isNotEmpty ? match.branchId : match.id;
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final user = ref.read(loginControllerProvider).user;
      final isAdmin = user?.role.toLowerCase() == 'admin';
      final branchId = isAdmin
          ? _branchIdForName(_selectedBranch)
          : _branchIdForName(_selectedBranch);
      final repo = ref.read(staffManagementRepositoryProvider);
      final staff = await repo.fetchStaff(branchId: branchId);
      if (!mounted) return;
      setState(() {
        _staffList = staff;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load staff';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Staff> _filteredStaff() {
    return _staffList.where((staff) {
      final search = _searchQuery.trim().toLowerCase();
      final matchesSearch =
          search.isEmpty ||
          staff.userName.toLowerCase().contains(search) ||
          staff.phoneNumber.toLowerCase().contains(search);
      final matchesRole = _selectedRole == null || staff.role == _selectedRole;
      final matchesStatus =
          _selectedStatus == null || staff.status == _selectedStatus;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = AppBreakpoints.isSmall(
      MediaQuery.of(context).size.width,
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isSmall
            ? AppBackButton(
                icon: Icons.home_outlined,
                tooltip: 'Home',
                onPressed: () => context.go(AppRoute.portal.path),
              )
            : null,
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
                setState(() => _searchQuery = value);
              },
              onAddPressed: widget.readOnly
                  ? null
                  : () {
                      context.push(AppRoute.staffAdd.path);
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
                    _loadStaff();
                  },
                ),
                AppFilterDropdown<String>(
                  hintText: 'Role',
                  allText: 'All Roles',
                  items: _roleOptions,
                  value: _selectedRole,
                  onChanged: (value) {
                    setState(() => _selectedRole = value);
                  },
                ),
                AppFilterDropdown<String>(
                  hintText: 'Status',
                  allText: 'All Status',
                  items: _statusOptions,
                  value: _selectedStatus,
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Per Figma: Add staff count text
            Text(
              '${_filteredStaff().length} Staff Members (limit 3)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : ListView.separated(
                      itemCount: _filteredStaff().length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final staff = _filteredStaff()[index];
                        return StaffListCard(
                          staffMember: staff,
                          onTap: () async {
                            final result = await context.push<Staff>(
                              AppRoute.staffDetail.path,
                              extra: staff,
                            );

                            if (result != null) {
                              final existingIndex = _staffList.indexWhere(
                                (item) => item.id == result.id,
                              );
                              if (existingIndex == -1) return;
                              setState(() {
                                _staffList[existingIndex] = result;
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
