import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/feedback/user_error_message.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/theme/responsive.dart';
import 'package:modular_pos/core/widgets/navigation/app_back_button.dart';
import 'package:modular_pos/features/branch/ui/viewmodels/branch_store.dart';
import 'package:modular_pos/features/branch/ui/view/branches/widgets/branch_card.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Branch'),
        leading: AppBackButton(
          onPressed: () => context.go(AppRoute.portal.path),
        ),
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
                      PopupMenuButton<String>(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _statusFilter ?? 'Status',
                                style: textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, size: 20),
                            ],
                          ),
                        ),
                        onSelected: (value) {
                          setState(() {
                            _statusFilter = value == 'All' ? null : value;
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'All', child: Text('All')),
                          const PopupMenuItem(
                            value: 'ACTIVE',
                            child: Text('Active'),
                          ),
                          const PopupMenuItem(
                            value: 'INACTIVE',
                            child: Text('Inactive'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Branch list
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
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
                                    AppRoute.branchDetail.path,
                                    extra: branch.id,
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
              ),
            ],
          );
        },
      ),
    );
  }
}
