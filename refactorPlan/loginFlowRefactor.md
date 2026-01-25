# Login Flow Refactor Plan

Goal: Make app load, login, tenant selection, and branch switching consistently hydrate policy + cash session state without blocking menu browsing.

## Phase 0 - Inventory + Baseline
- [x] Map current login/tenant selection flow in `login_controller.dart`.
  - Initial session: `_applySessionContext` + `_resetPolicies` + `_refreshPolicies(branchId)` + `_refreshCashSession`.
  - Login: same as above after successful auth.
  - Tenant selection: same as above after selecting tenant.
  - Logout: clears tokens, invalidates policy + cash session providers.
- [x] Confirm current policy + cash session hydration triggers.
  - `PolicyNotifier.build` watches `authActiveBranchIdProvider`, triggers `load` on first build or branch change.
  - `CashSessionViewModel.build` watches auth token + active branch, triggers `load`.
- [x] Identify where branch selection lives in admin portal and how it updates state.
  - `_BranchSection` uses local `_selectedBranchId` only and has TODOs to trigger refresh.
  - No provider currently updates `authActiveBranchIdProvider`; it still derives from session payload.

## Phase 1 - Source of Truth for Active Branch
- [x] Add a branch override provider (selected branch) separate from session payload.
- [x] Update `authActiveBranchIdProvider` to use override -> session active branch.
- [x] Ensure branch selector in admin portal writes to the override provider.

## Phase 2 - Hydration Consistency
- [x] On app bootstrap + login + tenant selection, invalidate policy + cash session state before loading.
- [x] Ensure policy + cash session viewmodels reload when active branch changes.
- [x] Confirm policy repository is always called with branchId.

## Phase 3 - Sale Gating Behavior
- [x] Allow browsing menu regardless of cash session.
- [x] Disable cart mutation (add item / checkout) when policy requires session and none active.
- [x] Ensure UI conveys disabled state without triggering network errors.

## Phase 4 - Manual Validation
- [ ] Fresh app start with saved session hydrates policy + cash session.
- [ ] Login/logout/login rehydrates policy reliably.
- [ ] Tenant selection triggers policy/cash session reload.
- [ ] Branch switch triggers policy reload and cash session reload.
- [ ] Sale page browse allowed; add-to-cart blocked when no session.

## Phase 5 - Cleanup
- [ ] Remove redundant hydration calls once branch-driven updates are reliable.
- [ ] Update docs/notes if needed.
