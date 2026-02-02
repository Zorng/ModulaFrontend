import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/staff/ui/widgets/app_filter_dropdown.dart';
import 'package:modular_pos/core/widgets/forms/app_search_add_bar.dart';
import 'package:modular_pos/features/staff/ui/widgets/staff_list_card.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/widgets/staff_data_table.dart';
import 'package:modular_pos/features/staff/ui/viewmodels/staff_list_store.dart';

class StaffListView extends ConsumerWidget {
  // Change to ConsumerWidget
  const StaffListView({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(StaffListAsyncNotifier.provider);
    final notifier = ref.read(StaffListAsyncNotifier.provider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = AppBreakpoints.isLarge(constraints.maxWidth);
        final isMediumOrLarge =
            AppBreakpoints.isMedium(constraints.maxWidth) ||
            AppBreakpoints.isLarge(constraints.maxWidth);

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: isWide
                ? null
                : AppBackButton(
                    icon: Icons.home_outlined,
                    tooltip: 'Home',
                    onPressed: () => context.go(AppRoute.portal.path),
                  ),
            title: const Text('Staff'),
          ),
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
                return isMediumOrLarge
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
                                      Expanded(
                                        flex: 2,
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
                                      const SizedBox(width: 12),
                                      AppFilterDropdown<String>(
                                        hintText: 'Branch',
                                        allText: 'All Branches',
                                        items: data.branchOptions,
                                        value: data.selectedBranch,
                                        onChanged:
                                            notifier.updateSelectedBranch,
                                      ),
                                      const SizedBox(width: 12),
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
                                      const SizedBox(width: 12),
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
                                      const SizedBox(width: 12),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 150,
                                          maxWidth: 200,
                                          minHeight: 48,
                                          maxHeight: 48,
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: readOnly
                                              ? null
                                              : () {
                                                  final branchId = notifier
                                                      .getBranchIdForAdd();
                                                  GoRouter.of(context)
                                                      .push(
                                                        AppRoute.staffForm.path,
                                                        extra: {
                                                          'branchId': branchId,
                                                        },
                                                      )
                                                      .then((result) {
                                                        if (result == true) {
                                                          notifier
                                                              .reloadStaff();
                                                        }
                                                      });
                                                },
                                          icon: const Icon(Icons.add, size: 20),
                                          label: const Text('Add New Staff'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
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
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Try adjusting your search or filters',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          margin: const EdgeInsets.all(16.0),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                    onSearchChanged: notifier.updateSearchQuery,
                                    onAddPressed: readOnly
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
                                              final result =
                                                  await context.pushNamed(
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
