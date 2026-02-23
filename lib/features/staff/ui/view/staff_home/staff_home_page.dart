import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/buttons/app_add_new_button.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/staff/ui/widgets/app_filter_dropdown.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/features/staff/ui/widgets/staff_list_card.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_data_table.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_list_store.dart';
import 'package:modular_pos/features/staff/data/staff_management_repository.dart';

class StaffHomePage extends ConsumerWidget {
  const StaffHomePage({
    super.key,
    this.readOnly = false,
    this.showAppBar = false,
  });

  final bool readOnly;
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(StaffListAsyncNotifier.provider);
    final notifier = ref.read(StaffListAsyncNotifier.provider.notifier);
    final useMock = ref.watch(useMockStaffRepositoryProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.isLarge(constraints.maxWidth);

        return Scaffold(
          appBar: showAppBar
              ? AppBar(
                  automaticallyImplyLeading: false,
                  leading:
                      AppBreakpoints.isLarge(MediaQuery.of(context).size.width)
                      ? null
                      : AppBackButton(
                          icon: Icons.home_outlined,
                          tooltip: 'Home',
                          onPressed: () => context.go(AppRoute.portal.path),
                        ),
                  title: const Text('Staff'),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Tooltip(
                        message: useMock
                            ? 'Using Mock Data (CRUD enabled)'
                            : 'Using Real API (Read-only)',
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                useMock ? Icons.science : Icons.cloud,
                                size: 16,
                                color: useMock
                                    ? Colors.orange.shade700
                                    : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                useMock ? 'Mock' : 'API',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: useMock
                                      ? Colors.orange.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          selected: useMock,
                          onSelected: (selected) {
                            ref
                                .read(useMockStaffRepositoryProvider.notifier)
                                .toggle();
                            notifier.reloadStaff();
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: useMock
                              ? Colors.orange.shade50
                              : Colors.blue.shade50,
                          checkmarkColor: useMock
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                          side: BorderSide(
                            color: useMock
                                ? Colors.orange.shade300
                                : Colors.blue.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(error.toString()),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: notifier.reloadStaff,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (data) {
                final filteredStaff = notifier.getFilteredStaff();
                return isWide
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 300,
                                        height: 48,
                                        child: TextField(
                                          onChanged: notifier.updateSearchQuery,
                                          decoration: InputDecoration(
                                            hintText: 'Search',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      SizedBox(
                                        width: 160,
                                        height: 56,
                                        child: DropdownMenu<String>(
                                          hintText: 'All Branches',
                                          textStyle: const TextStyle(
                                            fontSize: 14,
                                          ),
                                          initialSelection: data.selectedBranch,
                                          onSelected:
                                              notifier.updateSelectedBranch,
                                          dropdownMenuEntries: [
                                            const DropdownMenuEntry(
                                              value: '__all__',
                                              label: 'All Branches',
                                            ),
                                            ...data.branchOptions.map(
                                              (branch) => DropdownMenuEntry(
                                                value: branch,
                                                label: branch,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 130,
                                        height: 56,
                                        child: DropdownMenu<String>(
                                          hintText: 'All Roles',
                                          textStyle: const TextStyle(
                                            fontSize: 14,
                                          ),
                                          initialSelection: data.selectedRole,
                                          onSelected:
                                              notifier.updateSelectedRole,
                                          dropdownMenuEntries: [
                                            const DropdownMenuEntry(
                                              value: '__all__',
                                              label: 'All Roles',
                                            ),
                                            const DropdownMenuEntry(
                                              value: 'Manager',
                                              label: 'Manager',
                                            ),
                                            const DropdownMenuEntry(
                                              value: 'Cashier',
                                              label: 'Cashier',
                                            ),
                                            const DropdownMenuEntry(
                                              value: 'Admin',
                                              label: 'Admin',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 130,
                                        height: 56,
                                        child: DropdownMenu<String>(
                                          hintText: 'All Status',
                                          textStyle: const TextStyle(
                                            fontSize: 14,
                                          ),
                                          initialSelection: data.selectedStatus,
                                          onSelected:
                                              notifier.updateSelectedStatus,
                                          dropdownMenuEntries: [
                                            const DropdownMenuEntry(
                                              value: '__all__',
                                              label: 'All Status',
                                            ),
                                            const DropdownMenuEntry(
                                              value: 'Active',
                                              label: 'Active',
                                            ),
                                            const DropdownMenuEntry(
                                              value: 'Invited',
                                              label: 'Invited',
                                            ),
                                            const DropdownMenuEntry(
                                              value: 'Disabled',
                                              label: 'Disabled',
                                            ),
                                            const DropdownMenuEntry(
                                              value: 'Archived',
                                              label: 'Archived',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Tooltip(
                                        message: notifier.isStaffLimitReached()
                                            ? 'Staff limit reached (${notifier.getActiveStaffCount()}/${data.maxStaffLimit}). Upgrade your plan to add more staff.'
                                            : 'Add a new staff member',
                                        child: SizedBox(
                                          height: 56,
                                          child: AppAddNewButton(
                                            label: '+ Add New Staff',
                                            onPressed:
                                                readOnly ||
                                                    notifier
                                                        .isStaffLimitReached()
                                                ? null
                                                : () {
                                                    final branchId = notifier
                                                        .getBranchIdForAdd();
                                                    GoRouter.of(context)
                                                        .push(
                                                          AppRoute
                                                              .staffForm
                                                              .path,
                                                          extra: {
                                                            'branchId':
                                                                branchId,
                                                          },
                                                        )
                                                        .then((result) {
                                                          if (result == true) {
                                                            notifier
                                                                .reloadStaff();
                                                          }
                                                        });
                                                  },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                if (filteredStaff.isEmpty)
                                  Expanded(
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 64,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No staff members found',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Try adjusting your search or filters',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isWide)
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Active Staff: ${notifier.getActiveStaffCount()} / ${data.maxStaffLimit}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          notifier
                                                              .isStaffLimitReached()
                                                          ? Colors
                                                                .orange
                                                                .shade700
                                                          : Colors
                                                                .grey
                                                                .shade700,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              if (notifier
                                                  .isStaffLimitReached()) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Colors.orange.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors
                                                          .orange
                                                          .shade300,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .warning_amber_rounded,
                                                        size: 16,
                                                        color: Colors
                                                            .orange
                                                            .shade700,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Limit Reached',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .orange
                                                              .shade700,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                          16,
                                          0,
                                          16,
                                          16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTableTheme.background,
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: StaffDataTable(
                                            staffList: filteredStaff,
                                            onStaffTap: (staff) async {
                                              final result = await context
                                                  .pushNamed(
                                                    AppRoute.staffDetail.name,
                                                    pathParameters: {
                                                      'id': staff.id ?? '',
                                                    },
                                                    extra: staff,
                                                  );
                                              if (result == true) {
                                                notifier.reloadStaff();
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1000),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppSearchAddBar(
                                    searchHint: 'Search',
                                    addButtonLabel: '+ Add Staff',
                                    onSearchChanged: notifier.updateSearchQuery,
                                    onAddPressed:
                                        readOnly ||
                                            notifier.isStaffLimitReached()
                                        ? null
                                        : () {
                                            final branchId = notifier
                                                .getBranchIdForAdd();
                                            GoRouter.of(context)
                                                .push(
                                                  AppRoute.staffForm.path,
                                                  extra: {'branchId': branchId},
                                                )
                                                .then((result) {
                                                  if (result == true) {
                                                    notifier.reloadStaff();
                                                  }
                                                });
                                          },
                                  ),
                                  if (notifier.isStaffLimitReached())
                                    Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.orange.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange.shade700,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Staff limit reached (${notifier.getActiveStaffCount()}/${data.maxStaffLimit}). Upgrade your plan to add more staff.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.orange.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 12.0,
                                    runSpacing: 12.0,
                                    children: [
                                      AppFilterDropdown<String>(
                                        hintText: 'Branch',
                                        allText: 'All Branches',
                                        items: data.branchOptions,
                                        value: data.selectedBranch,
                                        onChanged:
                                            notifier.updateSelectedBranch,
                                      ),
                                      AppFilterDropdown<String>(
                                        hintText: 'Role',
                                        allText: 'All Roles',
                                        items: const [
                                          'Manager',
                                          'Cashier',
                                          'Admin',
                                        ],
                                        value: data.selectedRole,
                                        onChanged: notifier.updateSelectedRole,
                                      ),
                                      AppFilterDropdown<String>(
                                        hintText: 'Status',
                                        allText: 'All Status',
                                        items: const [
                                          'Active',
                                          'Invited',
                                          'Disabled',
                                          'Archived',
                                        ],
                                        value: data.selectedStatus,
                                        onChanged:
                                            notifier.updateSelectedStatus,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    '${filteredStaff.length} Staff Members (limit 3)',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: filteredStaff.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No staff members found',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.grey.shade600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your search or filters',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey.shade500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 1000,
                                      ),
                                      child: ListView.separated(
                                        itemCount: filteredStaff.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final staff = filteredStaff[index];
                                          return StaffListCard(
                                            staffMember: staff,
                                            onTap: () async {
                                              final result = await context
                                                  .pushNamed(
                                                    AppRoute.staffDetail.name,
                                                    pathParameters: {
                                                      'id': staff.id ?? '',
                                                    },
                                                    extra: staff,
                                                  );
                                              if (result == true) {
                                                notifier.reloadStaff();
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      );
              },
            ),
          ),
        );
      },
    );
  }
}
