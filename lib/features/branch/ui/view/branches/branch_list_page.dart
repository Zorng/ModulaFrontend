import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/app_table_theme.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/branch/data/branch_providers.dart';
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
    final useMock = ref.watch(useMockBranchRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Branches'),
        automaticallyImplyLeading: false,
        leading: isWideScreen
            ? null
            : AppBackButton(
                icon: Icons.home_outlined,
                tooltip: 'Home',
                onPressed: () => context.go(AppRoute.portal.path),
              ),
        actions: [
          if (useMock)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message: 'Using Mock Data',
                child: Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.science,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Mock',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange.shade50,
                  side: BorderSide(
                    color: Colors.orange.shade300,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = AppBreakpoints.isLarge(constraints.maxWidth);

                if (isWide) {
                  // Wide layout: white rounded container with filters + table
                  return Padding(
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
                            // Filter bar
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 300,
                                    height: 48,
                                    child: TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _searchQuery = value.toLowerCase();
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Search',
                                        prefixIcon: const Icon(Icons.search),
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
                                    width: 150,
                                    height: 56,
                                    child: DropdownMenu<String>(
                                      hintText: 'All Status',
                                      textStyle: const TextStyle(fontSize: 14),
                                      initialSelection: _statusFilter ?? 'All',
                                      onSelected: (value) {
                                        setState(() {
                                          _statusFilter =
                                              value == 'All' ? null : value;
                                        });
                                      },
                                      dropdownMenuEntries: const [
                                        DropdownMenuEntry(
                                          value: 'All',
                                          label: 'All Status',
                                        ),
                                        DropdownMenuEntry(
                                          value: 'ACTIVE',
                                          label: 'Active',
                                        ),
                                        DropdownMenuEntry(
                                          value: 'FROZEN',
                                          label: 'Inactive',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            // Table content
                            if (filteredBranches.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.store_outlined,
                                        size: 64,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty &&
                                                _statusFilter == null
                                            ? 'No branches found'
                                            : 'No branches match your filters',
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 16,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTableTheme.background,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: BranchDataTable(
                                        branchList: filteredBranches,
                                        onBranchTap: (branch) {
                                          showDialog(
                                            context: context,
                                            builder: (context) =>
                                                BranchDetailDialog(
                                              branchId: branch.id,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Mobile layout
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
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
                              _statusFilter =
                                  value == 'All' ? null : value;
                            });
                          },
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(
                              value: 'All',
                              label: 'All Status',
                            ),
                            DropdownMenuEntry(
                              value: 'ACTIVE',
                              label: 'Active',
                            ),
                            DropdownMenuEntry(
                              value: 'FROZEN',
                              label: 'Inactive',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: filteredBranches.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.store_outlined,
                                    size: 64,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isEmpty &&
                                            _statusFilter == null
                                        ? 'No branches found'
                                        : 'No branches match your filters',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => ref
                                  .read(branchStoreProvider.notifier)
                                  .refresh(),
                              child: ListView.builder(
                                itemCount: filteredBranches.length,
                                itemBuilder: (context, index) {
                                  final branch = filteredBranches[index];
                                  return BranchCard(
                                    branch: branch,
                                    onTap: () {
                                      context.push(
                                        AppRoute.branchDetail.path
                                            .replaceFirst(
                                              ':id',
                                              branch.id,
                                            ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}