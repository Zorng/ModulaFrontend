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
import 'package:modular_pos/features/staff/ui/viewmodels/staff_list_store.dart';

class StaffListView extends ConsumerWidget {
  // Change to ConsumerWidget
  const StaffListView({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(StaffListAsyncNotifier.provider);
    final notifier = ref.read(StaffListAsyncNotifier.provider.notifier);

    final isSmall = AppBreakpoints.isSmall(MediaQuery.of(context).size.width);

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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSearchAddBar(
                  searchHint: 'Search',
                  onSearchChanged: notifier.updateSearchQuery,
                  onAddPressed: readOnly
                      ? null
                      : () {
                          final branchId = notifier.getBranchIdForAdd();
                          GoRouter.of(context).push(
                            AppRoute.staffForm.path,
                            extra: {'branchId': branchId},
                          ).then((result) {
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
                      onChanged: notifier.updateSelectedBranch,
                    ),
                    AppFilterDropdown<String>(
                      hintText: 'Role',
                      allText: 'All Roles',
                      items: const ['Manager', 'Cashier', 'Admin'],
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
                      onChanged: notifier.updateSelectedStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '${filteredStaff.length} Staff Members (limit 3)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredStaff.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final staff = filteredStaff[index];
                      return StaffListCard(
                        staffMember: staff,
                        onTap: () async {
                          final result = await context.pushNamed(
                            AppRoute.staffDetail.name,
                            pathParameters: {'id': staff.id ?? ''},
                            extra: staff,
                          );
                          // Result is true if staff was updated/edited
                          if (result == true) {
                            // Reload list to fetch fresh updates
                            notifier.reloadStaff();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
