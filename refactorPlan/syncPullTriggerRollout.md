# Sync Pull Trigger Rollout Plan

Goal: wire automatic `sync/pull` triggering into the real app lifecycle so the new cache-first stores can converge without relying only on manual feature loads.

This plan follows the foundations already locked in:
- [offlineCachingFoundation.md](/Users/mac/flutterProjects/modular/refactorPlan/offlineCachingFoundation.md)
- [offlineCachingImplementationTracker.md](/Users/mac/flutterProjects/modular/refactorPlan/offlineCachingImplementationTracker.md)

## Scope lock

### In scope
- trigger `sync/pull` automatically from real lifecycle points
- reuse the shared orchestrator:
  - [sync_pull_orchestrator.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_pull_orchestrator.dart)
- define the first production trigger set:
  - login/app hydration
  - tenant switch
  - branch switch
  - reconnect
- define initial module-scope sets per trigger
- define stale-cache behavior while sync is running or fails
- add rollout-safe protections against duplicate or noisy pull traffic

### Explicitly out of scope
- `sync/push` offline replay
- background polling loop
- SSE / notifications wake-up integration
- TTL-based cache eviction
- feature-specific offline write enablement

---

## Current state

Already implemented:
- cache-first read stores for:
  - `policy`
  - `cashSession`
  - `menu`
  - `attendance`
  - `shift`
- shared checkpoint persistence
- shared `sync/pull` orchestrator
- real pull consumers for the same first-wave modules

Missing:
- automatic trigger points
- common scope-set selection
- shared stale/freshness surfacing
- duplicate-run protection at the app lifecycle level

---

## Trigger model (locked direction)

### 1. Hydration trigger
Run `sync/pull` after auth context is usable:
- access token present
- tenant present
- branch present when branch-scoped modules are included

Initial behavior:
- hydrate feature stores as they do today
- also trigger orchestrated `sync/pull` in the background

### 2. Tenant switch trigger
When active tenant changes:
- load tenant-partitioned cache immediately
- trigger tenant-scoped and branch-scoped pull once branch context becomes valid

### 3. Branch switch trigger
When active branch changes:
- render new branch partition immediately if cached
- trigger `sync/pull` for the new branch context

### 4. Reconnect trigger
When connectivity returns after offline/unreachable state:
- replay a read convergence pull for the active context
- do not force a full bootstrap unless checkpoint is missing or explicitly invalid

---

## Initial scope-set strategy (proposed)

Use conservative, explicit scope sets first.

### A. Branch-scoped workspace convergence
Use for hydration, branch switch, reconnect while inside branch work:
- `policy`
- `cashSession`
- `menu`
- `attendance`
- `shift`

### B. Tenant-only convergence
Use only where branch context is not available yet:
- no branch-scoped pull yet
- wait until branch context exists

Rule:
- do not send fake empty-branch pulls for branch-sensitive modules
- wait for a valid branch context instead

---

## Runtime rules

### 1. Cached UI stays visible
- do not blank cache while orchestrated pull is running
- do not reset feature state just because sync is in-flight

### 2. Pull failure does not destroy checkpoint success
- already handled in the orchestrator
- trigger layer must preserve that behavior

### 3. Avoid duplicate runs
- do not fire multiple identical pulls for the same context/scope set back-to-back
- trigger layer needs a lightweight dedupe gate:
  - same context
  - same scope set
  - already running or just completed very recently

### 4. Stale cache remains usable
- if pull fails:
  - keep cache rendered
  - surface refresh failure as stale/offline
- no forced eviction

---

## Implementation phases

## Phase 0 — Trigger Inventory
- [x] Inventory current lifecycle seams:
  - [app_hydration_listener.dart](/Users/mac/flutterProjects/modular/lib/core/hydration/app_hydration_listener.dart)
  - auth/tenant/branch providers
  - any existing reconnect or connectivity seam
- [x] Confirm there is no current global connectivity provider
- [x] Lock first production trigger points

Output:
- trigger inventory + chosen first rollout points

### Phase 0 findings

#### 1. Existing lifecycle seam
The current app already has one reliable lifecycle bridge:
- [app_hydration_listener.dart](/Users/mac/flutterProjects/modular/lib/core/hydration/app_hydration_listener.dart)

It already reacts to:
- login/session changes
- tenant changes
- active branch changes

And it already triggers branch-scoped feature refreshes for:
- `policy`
- `cashSession`

So this is the correct first place to integrate orchestrated `sync/pull`.

#### 2. Context providers available for trigger resolution
The trigger layer can already resolve auth context from:
- [auth_tenant_provider.dart](/Users/mac/flutterProjects/modular/lib/features/auth/domain/auth_tenant_provider.dart)
- [auth_branch_provider.dart](/Users/mac/flutterProjects/modular/lib/features/auth/domain/auth_branch_provider.dart)
- [active_branch_context_provider.dart](/Users/mac/flutterProjects/modular/lib/features/auth/domain/active_branch_context_provider.dart)

That means no new context model is needed for phase 1.

#### 3. No current global reconnect seam
There is currently:
- no `connectivity_plus`
- no shared online/offline provider
- no reconnect listener
- no app-wide network status stream

Current offline handling is per-request error mapping only.

So reconnect-triggered `sync/pull` cannot be wired in phase 1 without first introducing a connectivity status source.

#### 4. Locked first production trigger points
Initial automatic trigger rollout should be:
1. login/app hydration
2. tenant switch
3. branch switch

Reconnect remains part of this plan, but it is a later implementation phase because the connectivity seam does not exist yet.

#### 5. Initial trigger strategy
For the first rollout:
- keep existing feature `load()` calls intact
- add background orchestrated `sync/pull` on top of them
- use one branch-scoped scope set when tenant + branch are both valid:
  - `policy`
  - `cashSession`
  - `menu`
  - `attendance`
  - `shift`

This is the lowest-risk way to introduce convergence without replacing current feature hydration in one step.

---

## Phase 1 — Trigger Controller
- [x] Introduce a small shared trigger controller under `lib/core/sync/`
- [x] Give it responsibility for:
  - deciding when a pull should run
  - deduping repeated requests
  - resolving scope sets
- [x] Keep the orchestrator as transport/apply only

Output:
- `sync/pull` trigger coordinator

### Phase 1 implementation

Added:
- [sync_pull_trigger_controller.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_pull_trigger_controller.dart)

Locked behavior:
- exposes a dedicated trigger controller instead of pushing lifecycle logic into the orchestrator
- resolves the first-wave branch workspace scope set centrally
- skips when:
  - sync context is missing
  - branch context is missing for branch-scoped convergence
  - the same context + scope set is already running
  - the same context + scope set just succeeded within the cooldown window
- returns a structured result instead of throwing through lifecycle callers
- logs failures and preserves the orchestrator as the transport/apply layer only

Test coverage added:
- [sync_pull_trigger_controller_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_pull_trigger_controller_test.dart)

---

## Phase 2 — Hydration / Context Wiring
- [x] Wire trigger controller into:
  - login hydration
  - tenant switch
  - branch switch
- [x] Ensure branch-scoped pull only runs when branch context is valid
- [x] Keep current feature `load()` paths intact during initial rollout

Output:
- automatic pull on real auth/context changes

### Phase 2 implementation

Updated:
- [app_hydration_listener.dart](/Users/mac/flutterProjects/modular/lib/core/hydration/app_hydration_listener.dart)

Locked behavior:
- existing `policy.load()` and `cashSession.load()` hydration calls remain unchanged
- the listener now also dispatches one background orchestrated pull for branch-scoped convergence
- trigger type is derived from the actual context change:
  - `hydration`
  - `tenantSwitch`
  - `branchSwitch`
- the listener awaits device ID before dispatching the background pull
- the listener re-checks tenant/branch/account context before dispatch, so a stale async trigger does not run against an old context

Test coverage extended:
- [app_hydration_listener_test.dart](/Users/mac/flutterProjects/modular/test/core/hydration/app_hydration_listener_test.dart)

---

## Phase 3 — Reconnect Wiring
- [x] Introduce or reuse a connectivity status source
- [x] Trigger convergence pull on reconnect
- [x] Avoid noisy reconnect loops

Output:
- reconnect-driven read convergence

### Phase 3 implementation

Added:
- [app_connectivity.dart](/Users/mac/flutterProjects/modular/lib/core/network/app_connectivity.dart)
- [app_connectivity_contract.dart](/Users/mac/flutterProjects/modular/lib/core/network/app_connectivity_contract.dart)
- [app_connectivity_source.dart](/Users/mac/flutterProjects/modular/lib/core/network/app_connectivity_source.dart)
- [app_connectivity_source_stub.dart](/Users/mac/flutterProjects/modular/lib/core/network/app_connectivity_source_stub.dart)
- [app_connectivity_source_web.dart](/Users/mac/flutterProjects/modular/lib/core/network/app_connectivity_source_web.dart)

Updated:
- [app_hydration_listener.dart](/Users/mac/flutterProjects/modular/lib/core/hydration/app_hydration_listener.dart)

Locked behavior:
- browser `online/offline` events are now the first global connectivity seam
- reconnect is detected as `offline -> online`
- reconnect dispatches one background branch-scoped convergence pull when auth + tenant + branch context are valid
- reconnect still reuses the same trigger controller, so in-flight and cooldown dedupe rules apply

Test coverage added:
- [app_connectivity_test.dart](/Users/mac/flutterProjects/modular/test/core/network/app_connectivity_test.dart)
- reconnect coverage added to [app_hydration_listener_test.dart](/Users/mac/flutterProjects/modular/test/core/hydration/app_hydration_listener_test.dart)

---

## Phase 4 — Stale/Freshness Surfacing
- [x] Define a shared view model/status helper for:
  - syncing
  - stale but usable
  - refresh failed
- [x] Integrate first with cache-first modules that already expose partial offline state
- [x] Keep UX passive, not blocking

Output:
- common stale/freshness surfacing rules

### Phase 4 implementation

Added:
- [sync_freshness.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_freshness.dart)
- [sync_freshness_banner.dart](/Users/mac/flutterProjects/modular/lib/core/widgets/sync/sync_freshness_banner.dart)

Updated:
- [sync_models.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_models.dart)
- [sync_pull_orchestrator.dart](/Users/mac/flutterProjects/modular/lib/core/sync/sync_pull_orchestrator.dart)
- [policy_page.dart](/Users/mac/flutterProjects/modular/lib/features/policy/ui/view/policy/policy_page.dart)
- [cashier_cash_session.dart](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/view/cash_session/cashier_cash_session.dart)

Locked behavior:
- workspace freshness is now derived from:
  - current branch workspace context
  - sync checkpoint metadata
  - current run-state
  - connectivity status
- shared passive states are now:
  - `syncing`
  - `stale but usable`
  - `refresh failed`
- sync run-state now carries a context-specific run key so freshness only surfaces for the active workspace context
- `policy` now shows the shared passive freshness banner and suppresses duplicate generic offline-stale copy
- `cashSession` now shows the shared passive freshness banner and suppresses the blocking red load-error banner when cached state is still usable during offline refresh failure

Test coverage added:
- [sync_freshness_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_freshness_test.dart)
- [cash_session_screen_test.dart](/Users/mac/flutterProjects/modular/test/cash_session/cash_session_screen_test.dart)

---

## Phase 5 — Validation
- [x] Unit test trigger dedupe rules
- [x] Unit test context-to-scope resolution
- [x] Widget/integration-style verification for:
  - login hydration
  - branch switch
  - reconnect after offline
- [x] Manual QA checklist for cache-first modules

Output:
- validated trigger rollout

### Phase 5 validation

Automated validation:
- trigger controller coverage remains in:
  - [sync_pull_trigger_controller_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_pull_trigger_controller_test.dart)
- orchestrator + checkpoint safety remains in:
  - [sync_pull_orchestrator_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_pull_orchestrator_test.dart)
- hydration, tenant switch, branch switch, and reconnect lifecycle verification remains in:
  - [app_hydration_listener_test.dart](/Users/mac/flutterProjects/modular/test/core/hydration/app_hydration_listener_test.dart)
- shared freshness derivation coverage was added in:
  - [sync_freshness_test.dart](/Users/mac/flutterProjects/modular/test/core/sync/sync_freshness_test.dart)
- first UI regression coverage for passive freshness surfacing was added in:
  - [cash_session_screen_test.dart](/Users/mac/flutterProjects/modular/test/cash_session/cash_session_screen_test.dart)

Validation commands run:
- `flutter analyze lib/core/sync/sync_models.dart lib/core/sync/sync_pull_orchestrator.dart lib/core/sync/sync_freshness.dart lib/core/widgets/sync/sync_freshness_banner.dart lib/features/policy/ui/view/policy/policy_page.dart lib/features/cash_session/ui/view/cash_session/cashier_cash_session.dart test/core/sync/sync_freshness_test.dart test/cash_session/cash_session_screen_test.dart test/core/sync/sync_pull_orchestrator_test.dart test/core/sync/sync_pull_trigger_controller_test.dart test/core/hydration/app_hydration_listener_test.dart`
- `flutter test test/core/sync/sync_freshness_test.dart test/cash_session/cash_session_screen_test.dart test/core/sync/sync_pull_orchestrator_test.dart test/core/sync/sync_pull_trigger_controller_test.dart test/core/hydration/app_hydration_listener_test.dart`

Manual QA checklist:
1. Log in with a branch-selected session and confirm the app still hydrates branch policy and cash-session screens normally.
2. Switch branches and confirm cached branch data appears immediately, then passively converges without blocking UI.
3. Open `Policy`, go offline, and confirm the passive freshness banner says cached workspace data is being shown instead of freezing the screen.
4. Open `Cash Session` with cached session data, go offline, and confirm the passive freshness banner replaces the heavy blocking error banner.
5. Reconnect the browser and confirm one background branch-workspace pull is dispatched without repeated noisy retries.

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 | Completed | Existing trigger seam is `AppHydrationListener`; no global connectivity/reconnect provider exists yet |
| 1 | Completed | Trigger controller added with branch-workspace scope resolution, in-flight dedupe, cooldown dedupe, and failure-safe result handling |
| 2 | Completed | Hydration listener now dispatches background pull on login, tenant switch, and branch switch without replacing existing feature loads |
| 3 | Completed | Connectivity seam added; reconnect now dispatches background branch-scoped convergence pull on `offline -> online` |
| 4 | Completed | Shared workspace freshness model + passive banner integrated first into policy and cash-session surfaces |
| 5 | Completed | Trigger/orchestrator/hydration coverage revalidated and manual QA checklist locked |
