import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/branch/ui/viewmodels/branch_store.dart';
import 'package:modular_pos/features/branch/ui/view/branches/widgets/branch_card.dart';
import 'package:modular_pos/features/branch/ui/view/branches/widgets/branch_data_table.dart';
import 'package:modular_pos/features/branch/ui/view/branches/widgets/branch_detail_dialog.dart';

class BranchListPage extends ConsumerStatefulWidget {
  const BranchListPage({super.key});

  @override
  ConsumerState<BranchListPage> createState() => _BranchListPageState();
}

class _BranchListPageState extends ConsumerState<BranchListPage> {
  String _searchQuery = '';
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    // Trigger load after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(branchStoreProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final branchesAsync = ref.watch(branchStoreProvider);
    final width = MediaQuery.of(context).size.width;
    final isWideScreen = AppBreakpoints.isLarge(width);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'All Branches',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: isWideScreen
            ? null
            : AppBackButton(
                onPressed: () => context.go(AppRoute.portal.path),
              ),
        automaticallyImplyLeading: !isWideScreen,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = AppBreakpoints.isLarge(constraints.maxWidth);
          final horizontalPadding = isWideScreen ? 24.0 : 16.0;
          final maxContentWidth = isWideScreen ? 1200.0 : double.infinity;

          return Column(
            children: [
              Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: Flex(
                    direction: isWideScreen ? Axis.horizontal : Axis.horizontal,
                    children: [
                      Expanded(
                        flex: isWideScreen ? 3 : 1,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownMenu<String>(
                        width: 150,
                        initialSelection: _statusFilter ?? 'All',
                        hintText: 'All Status',
                        requestFocusOnTap: false,
                        textStyle: textTheme.bodyMedium,
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                        ),
                        onSelected: (value) {
                          setState(() {
                            _statusFilter = value == 'All' ? null : value;
                          });
                        },
                        dropdownMenuEntries: const [
                          DropdownMenuEntry(value: 'All', label: 'All Status'),
                          DropdownMenuEntry(value: 'ACTIVE', label: 'Active'),
                          DropdownMenuEntry(value: 'FROZEN', label: 'Inactive'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Branch list
              Expanded(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: branchesAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            UserErrorMessage.build(
                              context: 'Failed to load branches',
                              error: error,
                            ),
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              ref.read(branchStoreProvider.notifier).refresh();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (branches) {
                      // Apply filters
                      var filteredBranches = branches.where((branch) {
                        final matchesSearch = _searchQuery.isEmpty ||
                            branch.name.toLowerCase().contains(_searchQuery) ||
                            (branch.address?.toLowerCase().contains(_searchQuery) ??
                                false);

                        final matchesStatus = _statusFilter == null ||
                            branch.status == _statusFilter;

                        return matchesSearch && matchesStatus;
                      }).toList();

                      if (filteredBranches.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.store_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty && _statusFilter == null
                                    ? 'No branches found'
                                    : 'No branches match your filters',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (isWideScreen) {
                        // Table layout for wide screens
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: BranchDataTable(
                            branchList: filteredBranches,
                            onBranchTap: (branch) {
                              showDialog(
                                context: context,
                                builder: (context) => BranchDetailDialog(
                                  branchId: branch.id,
                                ),
                              );
                            },
                          ),
                        );
                      }

                      // Card layout for narrow screens
                      return RefreshIndicator(
                        onRefresh: () =>
                            ref.read(branchStoreProvider.notifier).refresh(),
                        child: ListView.builder(
                          itemCount: filteredBranches.length,
                          itemBuilder: (context, index) {
                            final branch = filteredBranches[index];
                            return BranchCard(
                              branch: branch,
                              onTap: () {
                                context.push(
                                  AppRoute.branchDetail.path.replaceFirst(':id', branch.id),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}