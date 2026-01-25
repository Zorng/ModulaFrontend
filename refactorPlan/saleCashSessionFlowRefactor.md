# Sale ↔ Cash Session Flow Refactor Plan

**Goal:** Align frontend Sale behavior with updated ModSpec rules:
- **Menu browsing is always allowed**
- If branch policy `cashRequireSessionForSales = true` and **no active cash session**, the user can **read-only browse** but **cannot create a draft cart / add items / checkout**.

**References**
- `docs/modSpec/sale_module.md` (v2.2) — **§3.7 Cash Session Dependency (UX Rule)**, **UC-2 Start Draft Order**
- `docs/modSpec/cashSession_module.md` (v1.5) — **UC-3 Record Cash Tender From Sale**, **Policies Used**
- `docs/modSpec/policy_module.md` — Cash Session Control Policies (`cashRequireSessionForSales`, etc.)

---

## 1) Problem Statement (what we’re fixing)

We currently gate Sale actions based on “cash session open” (hardcoded in some places), but:
- The ModSpec states the gate is **policy-driven** (`cashRequireSessionForSales`, branch-scoped), not always-on.
- Users should still be able to **view menu and item details** without a cash session.
- When a cash session is required but missing, the UI must be **read-only** and must not create draft carts (no backend draft creation either).

---

## 2) Desired UX (target behavior)

### A) Policy requires session + no session open (Read-only Sale)
- User can open Sale and browse categories/items, and open item detail.
- “Add Item” / “Add to cart” is disabled (with helper text).
- Cart FAB / navigation is disabled OR opens a read-only cart with “Start cash session to sell”.
- Checkout is disabled.
- Provide a single clear action: **Go to Cash Session**.

### B) Policy requires session + session open (Normal Sale)
- Full Sale flow enabled: add items → cart → precheckout → checkout.

### C) Policy does NOT require session
- Full Sale flow enabled even if no session open.

---

## 3) Architecture Approach (how we’ll refactor)

### 3.1 Introduce a single “Sale Access Gate” source of truth
Create a shared computation that answers:
- `requiresCashSessionForSales` (from Policy, branch-scoped)
- `cashSessionOpen` (from Cash Session VM, branch-scoped)
- `canCreateDraftSale` / `canAddToCart` / `canCheckout`
- `blockingReason` (string for UI)

This avoids scattered “if session open” checks and prevents accidental bypass.

### 3.2 Make the gate policy-driven (remove hardcoding)
Policy model currently covers sales + inventory; we must add **cash session policy** fields:
- `cashRequireSessionForSales`
- (optional for later UX): `cashAllowPaidOut`, `cashRequireRefundApproval`, `cashAllowManualAdjustment`

### 3.3 Apply the gate at ALL entry points that can create a draft
At minimum:
- Sale item “Add Item” action
- Sale grid item “Add selection” call path
- Cart page actions that might create draft / call precheckout / finalize
- Any “auto-create draft” behavior (if present)

---

## 4) Implementation Checklist (track progress here)

### Phase 0 — Baseline & Mapping
- [x] Identify all code paths that can create a sale draft (local + backend)
  - Backend draft creation: `SaleCartNotifier._ensureSaleId()` → `SaleRepository.ensureDraft()` → `SaleApi.createDraft()` → `POST /v1/sales/drafts`
  - Draft recreation on type change: `SaleCartNotifier.setSaleType()` (mid-cart) → `SaleRepository.ensureDraft()` → `POST /v1/sales/drafts` (+ replays items)
  - Primary trigger: `SalePage` item tap → `SaleItemDetailPage` returns `SaleItemSelectionResult` → `saleCartProvider.notifier.addSelection()` (calls `_ensureSaleId()`)
  - Not used (present but unused): `SaleApi.getOrCreateDraft()`
- [x] Identify all UI entry points into Sale & Cart (portal → sale, sale → item, sale → cart)
  - Portal → Sale: `admin_portal.dart` / `cashier_portal.dart` → `context.push(AppRoute.sale.path)` (route `/sale`)
  - Sale → Item detail: `SalePage` grid item → `Navigator.push(SaleItemDetailPage)`
  - Item detail → draft creation: "Add Item" returns selection to `SalePage`, which calls `SaleCartNotifier.addSelection()`
  - Sale → Cart page: `SalePage` FAB → `Navigator.push(SaleCartPage)`
- [x] Confirm where branch context comes from (auth session vs user selection)
  - Cash Session branch: `CashSessionViewModel._currentBranchId()` picks from `loginControllerProvider.session.user.branches` (first active), not from Menu selected branch.
  - Menu branch: `MenuViewModel` supports `selectedBranchId` (including “all”) and loads menu per-branch.
  - Sale API calls: no explicit branch id passed; backend likely infers from auth/tenant context.

### Phase 1 — Policy Model: add Cash Session Control policies
- [x] Add `CashSessionPolicy` to `lib/features/policy/domain/models/policy.dart`
- [x] Extend `PolicyBundle` + `PolicyState` to include cash-session policy
- [x] Parse `cashRequireSessionForSales` from `GET /v1/policies` payload
- [x] Expose it via `policyNotifierProvider` state

### Phase 2 — Create a shared “SaleAccessGate”
- [x] Add a provider/helper (e.g., `saleAccessGateProvider`) that combines:
  - `policyNotifierProvider` (cashRequireSessionForSales)
  - `cashSessionViewModelProvider` (sessionStatus)
  - current branch id used by both modules
- [x] Ensure it is branch-aware and reactive to branch changes

### Phase 3 — UI Wiring (read-only mode)
- [x] `lib/features/sale/ui/view/sale_page.dart`
  - [x] Don’t block navigation to Sale
  - [x] Show “cash session required” prompt/banner only when gate blocks creation
  - [x] Disable Cart FAB (or make it read-only) when gate blocks creation
- [x] `lib/features/sale/ui/view/sale_item_detail_page.dart`
  - [x] Disable “Add Item” only when gate blocks creation (policy + session)
  - [x] Keep item details fully viewable
- [x] `lib/features/sale/ui/view/sale_cart_page.dart`
  - [x] If gate blocks creation, prevent checkout and show clear CTA

### Phase 4 — ViewModel / Data Layer Guards (no bypass)
- [x] `lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart`
  - [x] Replace `_enforceCashSession = true` with policy-driven check
  - [x] Ensure `_ensureSaleId`, `addSelection`, `checkout` respect the gate
  - [x] Ensure blocked paths do not create backend drafts

### Phase 5 — Navigation correctness (role-aware)
- [x] Make “Go to Cash Session” route role-aware (admin vs cashier portal paths)
- [x] Ensure Cash Session screen back button returns to the correct portal (not Sale)

### Phase 6 — QA / Acceptance Criteria
- [x] Policy `cashRequireSessionForSales=true`, session closed:
  - [x] Sale opens, menu browsable
  - [x] Add Item disabled
  - [x] Cart/checkout blocked
  - [x] “Go to Cash Session” works, returns safely
- [x] Policy `cashRequireSessionForSales=true`, session open:
  - [x] Full sale flow works
- [x] Policy `cashRequireSessionForSales=false`:
  - [x] Full sale flow works without session

---

## 5) Known Gaps / Decisions

1) **Draft cart persistence**
- ModSpec says draft cart is local-only (no server write).
- Current implementation may create a backend draft sale ID early.
- **Decision:** For this refactor, focus on gating (prevent draft creation when blocked). A later refactor can align drafts to local-only if desired.

2) **Branch-scoped policy**
- Policy is branch-scoped by spec. Ensure frontend loads policies for the *active branch* used by Sale/Cash Session.

---

## 6) Progress Log

Use this section to append brief updates while refactoring.

- 2025-12-22: Created plan.
- 2025-12-22: Phase 0 completed (mapped draft creation paths, sale/cart entry points, and current branch context sources).
- 2025-12-22: Phase 1 completed (added `CashSessionPolicy`, wired through Policy repo/state, and made parsing tolerant of `{data: ...}` envelopes).
- 2025-12-22: Phase 2 completed (added `authActiveBranchIdProvider` + `saleAccessGateProvider` as the shared policy/session gate).
- 2025-12-22: Phase 3 completed (Sale is browsable without session; Item “Add” + Cart editing/checkout are disabled when cash session is required but not active, with clear CTA to Cash Session).
- 2025-12-22: Phase 4 completed (sale cart viewmodel now enforces policy-driven cash-session gate to prevent draft creation/checkout bypass).
- 2025-12-22: Phase 5 completed (added admin cash session route and role-aware navigation; cash session back always returns to correct portal).
- 2025-12-23: Phase 6 completed (validated acceptance criteria via unit/widget tests: read-only sale UX when blocked + draft creation allowed when session open or policy disabled).
- 2025-12-23: Fixed false-positive “session open” state when backend returns non-session payloads (e.g. `{success:false,...}`), which could bypass AC-2 and allow add/checkout without an active cash session.
