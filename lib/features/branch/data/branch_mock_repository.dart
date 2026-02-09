import 'package:modular_pos/features/branch/domain/models/branch.dart';

/// Mock branch repository for testing without backend API.
/// Stores changes in memory - changes are lost on refresh.
class BranchMockRepository {
  // In-memory storage for branch updates
  final Map<String, Branch> _updatedBranches = {};

  /// List all accessible branches (mock data)
  Future<List<Branch>> listBranches() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    // Return mock data with any updates applied
    final mockBranches = _getMockBranches();
    return mockBranches.map((branch) {
      return _updatedBranches[branch.id] ?? branch;
    }).toList();
  }

  /// Get a single branch by ID
  Future<Branch> getBranch(String branchId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final branches = await listBranches();
    return branches.firstWhere(
      (b) => b.id == branchId,
      orElse: () => throw Exception('Branch not found'),
    );
  }

  /// Update branch profile (mocked)
  Future<Branch> updateBranch({
    required String branchId,
    String? name,
    String? address,
    String? contactPhone,
    String? contactEmail,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate save delay
    
    final currentBranch = await getBranch(branchId);
    final updatedBranch = currentBranch.copyWith(
      name: name ?? currentBranch.name,
      address: address ?? currentBranch.address,
      contactPhone: contactPhone ?? currentBranch.contactPhone,
      contactEmail: contactEmail ?? currentBranch.contactEmail,
      updatedAt: DateTime.now(),
    );
    
    // Store the update in memory
    _updatedBranches[branchId] = updatedBranch;
    
    return updatedBranch;
  }

  /// Freeze a branch (mocked)
  Future<Branch> freezeBranch(String branchId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final currentBranch = await getBranch(branchId);
    final frozenBranch = currentBranch.copyWith(
      status: 'FROZEN',
      updatedAt: DateTime.now(),
    );
    
    _updatedBranches[branchId] = frozenBranch;
    return frozenBranch;
  }

  /// Unfreeze a branch (mocked)
  Future<Branch> unfreezeBranch(String branchId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final currentBranch = await getBranch(branchId);
    final activeBranch = currentBranch.copyWith(
      status: 'ACTIVE',
      updatedAt: DateTime.now(),
    );
    
    _updatedBranches[branchId] = activeBranch;
    return activeBranch;
  }

  /// Clear all mock updates (for testing)
  void clearUpdates() {
    _updatedBranches.clear();
  }

  /// Get mock branch data
  List<Branch> _getMockBranches() {
    final now = DateTime.now();
    return [
      Branch(
        id: 'branch-1',
        tenantId: 'tenant-1',
        name: 'Downtown Branch',
        status: 'ACTIVE',
        address: '123 Main Street, City Center',
        contactPhone: '+1234567890',
        contactEmail: 'downtown@example.com',
        managedBy: 'Sarah Johnson',
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      Branch(
        id: 'branch-2',
        tenantId: 'tenant-1',
        name: 'Westside Mall',
        status: 'ACTIVE',
        address: '456 West Avenue, Shopping District',
        contactPhone: '+1234567891',
        contactEmail: 'westside@example.com',
        managedBy: 'Michael Chen',
        createdAt: now.subtract(const Duration(days: 300)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      Branch(
        id: 'branch-3',
        tenantId: 'tenant-1',
        name: 'Airport Terminal',
        status: 'FROZEN',
        address: '789 Airport Road, Terminal 2',
        contactPhone: '+1234567892',
        contactEmail: 'airport@example.com',
        managedBy: 'Emily Rodriguez',
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now.subtract(const Duration(days: 60)),
      ),
      Branch(
        id: 'branch-4',
        tenantId: 'tenant-1',
        name: 'North Plaza',
        status: 'ACTIVE',
        address: '321 North Boulevard, Plaza Center',
        contactPhone: '+1234567893',
        contactEmail: 'north@example.com',
        managedBy: 'David Kim',
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      Branch(
        id: 'branch-5',
        tenantId: 'tenant-1',
        name: 'Seaside Location',
        status: 'ACTIVE',
        address: '555 Beach Road, Coastal Area',
        contactPhone: '+1234567894',
        contactEmail: null,
        managedBy: 'Jessica Martinez',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
