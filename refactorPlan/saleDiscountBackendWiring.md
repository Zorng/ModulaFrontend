# Sale Discount Backend Wiring

Status: In progress  
Owner context: Frontend POS / Discount + Sale integration

## Goal

Complete the discount feature beyond its current UI-only state:

- wire discount management to the real backend
- align role access with the contract
- connect Sale to discount eligibility resolution
- lock discount snapshots into sale/order flows

This is not just a discount-management task. It is also a sale-pricing integration task.

---

## Locked source of truth

Use these as the canonical references:

- [discount-v0.md](/Users/mac/flutterProjects/modular/integration/discount-v0.md)
- [discount_module.md](/Users/mac/flutterProjects/modular/docs/modSpec/discount_module.md)
- [sale_module.md](/Users/mac/flutterProjects/modular/docs/modSpec/sale_module.md)
- [sale-order-v0.md](/Users/mac/flutterProjects/modular/integration/sale-order-v0.md)

Important contract rules already locked there:

- Discount resolves eligibility and scope only.
- Sale computes money math.
- Sale must snapshot applied discounts on finalize.
- Managers and cashiers can read discount rules.
- Only admin/owner can mutate discount rules.

---

## Current status

### What is already in place

- Discount list/detail/form UI exists.
- Discount routes exist and are reachable from tenant navigation.
- A real remote discount API + repository already exists for:
  - rule list/detail
  - create/update
  - activate/deactivate/archive
  - item preflight
- Discount form already integrates with:
  - branch selection
  - branch menu item selection

### What is still missing or wrong

#### 1. Runtime discount repository is still mock-backed

- [discount_repository.dart](/Users/mac/flutterProjects/modular/lib/features/discount/data/discount_repository.dart)
  currently defaults `useMockDiscountRepositoryProvider` to `true`
- there is no `DISCOUNT_REPOSITORY_MODE` support in:
  - [app_env.dart](/Users/mac/flutterProjects/modular/lib/core/config/app_env.dart)
  - [.env.example](/Users/mac/flutterProjects/modular/.env.example)

Meaning:
- the UI may look wired, but normal runtime still does not reliably use `/v0/discount`

#### 2. Router access is stricter than the product contract

- [app.dart](/Users/mac/flutterProjects/modular/lib/app.dart)
  blocks the discount route for everyone except admin/owner

But the contract says:
- manager and cashier must have read-only visibility

#### 3. Discount list filtering is still frontend-only

- [discount_list_controller.dart](/Users/mac/flutterProjects/modular/lib/features/discount/ui/viewmodels/discount_list_controller.dart)
  loads all rules without passing status/scope/search to backend
- [discount_list_state.dart](/Users/mac/flutterProjects/modular/lib/features/discount/ui/viewmodels/discount_list_state.dart)
  filters locally

That is acceptable for early UI, but not the finished integration.

#### 4. Sale does not resolve discount eligibility at all

Missing seam:
- no sale-side client for `POST /v0/discount/eligibility/resolve`

Current behavior:
- cart pricing still uses only base price + modifiers
- no line/item/branch discount model exists in cart state
- no discount snapshot is generated before checkout/finalize

#### 5. Sale/order payloads still hardcode zero discount

- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  still sends `discountUsd: 0` in order checkout payloads

That means sale/order flows are not discount-aware yet even when the management module exists.

#### 6. There is no end-to-end discount test coverage yet

Current tests mostly prove:
- UI behavior
- controller logic
- mock repository behavior

What is still missing:
- discount remote API tests
- discount repository integration tests
- sale pricing integration tests with resolved discount rules
- receipt/order/reporting projection checks for non-zero discount

---

## Scope lock

### In scope

- discount management backend cutover
- read-only access for manager/cashier
- backend query-backed discount list filters
- sale discount eligibility resolution
- discount-aware cart pricing and checkout snapshot
- discount propagation into sale/order/receipt surfaces
- focused test coverage for the new seams

### Out of scope

- fixed-amount discounts
- coupon/voucher codes
- customer-specific discounts
- sale-type-specific discounts
- redesigning the existing discount UI from scratch

Important rule:

- no manual cashier-entered discount workflow should be introduced
- discount remains policy-driven only

---

## Phase 0 — Contract Lock + Inventory

- [x] Lock the current backend contract and sale responsibility split
- [x] Inventory every existing discount runtime seam
- [x] Inventory every sale pricing seam that will need discount input
- [x] Inventory every finalized-sale / order / receipt surface that should display discount truth

Output:

- a complete seam map from discount management through finalized sale

### Phase 0 result

#### A. Locked responsibility split

From the current contracts/spec:

- Discount owns:
  - rule management
  - item preflight validation
  - eligibility resolution metadata
- Sale owns:
  - line pricing
  - stacking application
  - subtotal / tax / total computation
  - finalized discount snapshot lock-in

That means:

- frontend must not try to make Discount compute money totals
- frontend must make Sale consume resolved discount metadata before finalize

#### B. Discount management runtime inventory

| Seam | Current state | File references | Assessment |
|---|---|---|---|
| Tenant navigation entry | Present | [app_navigation_config.dart#L67](/Users/mac/flutterProjects/modular/lib/core/widgets/navigation/app_navigation_config.dart#L67) | Discount workspace is exposed in tenant nav for admin/owner. |
| Discount list page | Present | [discount_page.dart#L17](/Users/mac/flutterProjects/modular/lib/features/discount/ui/view/discount/discount_page.dart#L17) | List UI exists and loads on enter. |
| Discount form/detail pages | Present | [discount_rule_form_page.dart](/Users/mac/flutterProjects/modular/lib/features/discount/ui/view/discount_rule_form/discount_rule_form_page.dart), [discount_rule_detail_page.dart](/Users/mac/flutterProjects/modular/lib/features/discount/ui/view/discount_rule_detail/discount_rule_detail_page.dart) | Create/edit/detail UI exists. |
| Remote discount API client | Present | [discount_api.dart#L17](/Users/mac/flutterProjects/modular/lib/features/discount/data/discount_api.dart#L17) | CRUD + lifecycle + item preflight already implemented. |
| Remote discount repository | Present | [remote_discount_repository.dart#L11](/Users/mac/flutterProjects/modular/lib/features/discount/data/remote_discount_repository.dart#L11) | DTO -> domain mapping exists. |
| Branch support provider | Present | [discount_support_providers.dart#L7](/Users/mac/flutterProjects/modular/lib/features/discount/ui/viewmodels/discount_support_providers.dart#L7) | Form can load tenant branches. |
| Branch menu item support provider | Present | [discount_support_providers.dart#L20](/Users/mac/flutterProjects/modular/lib/features/discount/ui/viewmodels/discount_support_providers.dart#L20) | Form can load branch-visible menu items. |
| Item preflight on save | Present | [discount_form_controller.dart#L263](/Users/mac/flutterProjects/modular/lib/features/discount/ui/viewmodels/discount_form_controller.dart#L263) | Item-level rule save already validates branch item eligibility. |
| Runtime repository mode | Missing / wrong default | [discount_repository.dart#L41](/Users/mac/flutterProjects/modular/lib/features/discount/data/discount_repository.dart#L41) | Discount runtime still defaults to mock. |
| Env/config support for discount repo mode | Missing | [app_env.dart#L33](/Users/mac/flutterProjects/modular/lib/core/config/app_env.dart#L33), [.env.example#L15](/Users/mac/flutterProjects/modular/.env.example#L15) | No `DISCOUNT_REPOSITORY_MODE` path exists yet. |
| Route access for manager/cashier read-only | Wrong | [app.dart#L148](/Users/mac/flutterProjects/modular/lib/app.dart#L148) | Router currently blocks non-admin/owner despite read-only contract. |
| List query uses backend filters | Missing | [discount_list_controller.dart#L25](/Users/mac/flutterProjects/modular/lib/features/discount/ui/viewmodels/discount_list_controller.dart#L25), [discount_list_state.dart#L31](/Users/mac/flutterProjects/modular/lib/features/discount/ui/viewmodels/discount_list_state.dart#L31) | List fetch is full-load then client-filter. |

#### C. Sale pricing inventory against discount integration

| Seam | Current state | File references | Assessment |
|---|---|---|---|
| Cart subtotal math | Base price + modifiers only | [sale_cart_viewmodel.dart#L229](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart#L229) | No discount input. |
| Cart tax math | Tax on undiscounted subtotal | [sale_cart_viewmodel.dart#L256](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart#L256) | Needs discount-aware subtotal first. |
| Cart pricing snapshot builder | No discount fields | [sale_cart_payload_builder.dart#L27](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_payload_builder.dart#L27) | Snapshot currently records only base/add-on/unit/line pricing. |
| Sale cart state | No discount state | [sale_cart_state.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_state.dart) | No place yet for resolved rule metadata or computed discount totals. |
| Discount eligibility resolve client | Missing | [discount_api.dart#L168](/Users/mac/flutterProjects/modular/lib/features/discount/data/discount_api.dart#L168) | Only item preflight exists; sale-side `eligibility/resolve` seam is absent. |
| Sale checkout payload math | Still flat subtotal/tax/total | [sale_cart_viewmodel.dart#L1023](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart#L1023) | No resolved discounts are included in checkout calculations. |
| Order checkout payload | Hardcoded zero discount | [sale_repository.dart#L725](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart#L725) | Explicit blocker for non-zero discount propagation. |
| Receipt print model | Subtotal/tax/total only | [sale_cart_viewmodel.dart#L1361](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart#L1361), [esc_pos_receipt_formatter.dart#L41](/Users/mac/flutterProjects/modular/lib/core/printing/esc_pos_receipt_formatter.dart#L41) | No receipt print field for discount yet. |

#### D. Finalized sale / order / receipt / reporting surface inventory

| Surface | Current state | File references | Assessment |
|---|---|---|---|
| Receipt dialog in sale cart | Shows items + total only | [sale_cart_panel.dart#L56](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart#L56) | No explicit discount breakdown. |
| Thermal receipt print | Shows subtotal, tax, total | [sale_cart_viewmodel.dart#L1361](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart#L1361), [esc_pos_receipt_formatter.dart#L186](/Users/mac/flutterProjects/modular/lib/core/printing/esc_pos_receipt_formatter.dart#L186) | Discount rows are not part of the print model. |
| Order checkout settlement payload | Includes placeholder `discountUsd: 0` | [sale_repository.dart#L725](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart#L725) | Downstream order settlement remains discount-blind. |
| Cash session sales UI | No discount-specific display | [session_sales_section.dart#L74](/Users/mac/flutterProjects/modular/lib/features/cash_session/ui/widgets/session_sales_section.dart#L74) | Will rely on backend-provided totals once sale discount truth is finalized. |
| Reporting UI | No discount-specific frontend seam found in current feature search | Search inventory only | Reporting contract already has discount fields, but frontend propagation work has not started. |

#### E. Phase 0 conclusions

1. Discount management is structurally built, but not runtime-complete.

- the remote lane exists
- the app still defaults to mock
- routing still blocks read-only roles that the contract allows

2. Sale discount integration has not started yet in any meaningful way.

- no eligibility resolution call
- no cart discount model
- no discount-aware pricing
- no snapshot lock-in seam

3. Downstream surfaces are still mostly flat-money only.

- receipt dialog
- thermal receipt print
- order settlement payloads
- likely reporting/cash-session projections

4. Recommended execution order stays locked:

- first make discount management real at runtime
- then wire sale pricing and snapshot lock-in

### Phase 0 completion note

Phase 0 is now complete. The tracker has enough concrete inventory to begin implementation without reopening discovery.

---

## Phase 1 — Discount Management Runtime Cutover

- [x] Add discount repository runtime mode support
  - `DISCOUNT_REPOSITORY_MODE`
  - env + app config wiring
- [x] Make runtime default consistent with current branch strategy
- [x] Confirm discount screens use remote repo without test-only overrides
- [x] Add focused API/repository tests for the implemented `/v0/discount` endpoints

Output:

- discount management is genuinely backend-backed at runtime

### Phase 1 result

What changed:

- added `DISCOUNT_REPOSITORY_MODE` support in:
  - [app_env.dart](/Users/mac/flutterProjects/modular/lib/core/config/app_env.dart)
  - [.env.example](/Users/mac/flutterProjects/modular/.env.example)
  - [.env.web.local.example](/Users/mac/flutterProjects/modular/.env.web.local.example)
  - [dart_define_run_guide.md](/Users/mac/flutterProjects/modular/handbook/handover/dart_define_run_guide.md)
  - [netlify_deploy.md](/Users/mac/flutterProjects/modular/handbook/handover/netlify_deploy.md)

- wired the discount repository mode to the app env in:
  - [discount_repository.dart](/Users/mac/flutterProjects/modular/lib/features/discount/data/discount_repository.dart)

- locked the runtime default to the real API lane:
  - `AppEnv.useMockDiscountRepository` now defaults to `api`
  - `discountRepositoryProvider` no longer hardcodes mock by default

- added focused runtime/API verification:
  - [discount_repository_provider_test.dart](/Users/mac/flutterProjects/modular/test/discount/discount_repository_provider_test.dart)
  - [discount_api_test.dart](/Users/mac/flutterProjects/modular/test/discount/discount_api_test.dart)

Important additional fix discovered during Phase 1:

- [discount_rule_list_envelope.dart](/Users/mac/flutterProjects/modular/lib/features/discount/data/dto/discount_rule_list_envelope.dart)
  was still parsing the discount list as if `data` were a raw list
- current backend contract returns `data.items`
- the envelope parser now supports the implemented list shape, which is required for real runtime loading to work

Validation:

- `flutter analyze lib/core/config/app_env.dart lib/features/discount/data/discount_repository.dart lib/features/discount/data/dto/discount_rule_list_envelope.dart test/discount/discount_api_test.dart test/discount/discount_repository_provider_test.dart test/discount/discount_pages_test.dart test/discount/discount_form_page_test.dart`
- `flutter test test/discount/discount_api_test.dart test/discount/discount_repository_provider_test.dart test/discount/discount_controllers_test.dart test/discount/discount_pages_test.dart test/discount/discount_form_page_test.dart`

---

## Phase 2 — Access / Routing Alignment

- [x] Update router gating so manager/cashier can open discount screens read-only
- [x] Keep create/edit/lifecycle mutation blocked for non-admin/owner
- [x] Preserve tenant-scope navigation and authorization rules
- [x] Add route/access tests for:
  - admin/owner manage access
  - manager/cashier read-only access

Output:

- frontend role behavior matches the discount contract

### Phase 2 result

What changed:

- split discount routing in [app.dart](/Users/mac/flutterProjects/modular/lib/app.dart)
  into:
  - read routes
    - list
    - detail
  - manage route
    - form

- manager/cashier can now open:
  - [AppRoute.discount](/Users/mac/flutterProjects/modular/lib/core/routing/app_router.dart)
  - [AppRoute.discountRuleDetail](/Users/mac/flutterProjects/modular/lib/core/routing/app_router.dart)
  as read-only routes

- manager/cashier are still blocked from:
  - [AppRoute.discountRuleForm](/Users/mac/flutterProjects/modular/lib/core/routing/app_router.dart)

- preserved the existing tenant-scope navigation model:
  - no new branch navigation destination was introduced
  - admin/owner tenant navigation still owns the explicit `Discounts` entry
  - manager/cashier access is direct-route/read-only, not a new branch-scope workspace

- added focused route coverage in:
  - [discount_route_access_test.dart](/Users/mac/flutterProjects/modular/test/discount/discount_route_access_test.dart)
    - admin can open manage form
    - manager can open list read-only
    - cashier can open detail read-only
    - cashier cannot open form route

- refreshed stale navigation expectations in:
  - [workspace_nav_config_test.dart](/Users/mac/flutterProjects/modular/test/core/navigation/workspace_nav_config_test.dart)
  - [workspace_navigation_widgets_test.dart](/Users/mac/flutterProjects/modular/test/core/navigation/workspace_navigation_widgets_test.dart)
  so tenant navigation tests match the existing `Discounts` destination already present for admin/owner

Validation:

- `flutter analyze lib/app.dart test/discount/discount_route_access_test.dart test/core/navigation/workspace_nav_config_test.dart test/core/navigation/workspace_navigation_widgets_test.dart`
- `flutter test test/discount/discount_route_access_test.dart test/discount/discount_pages_test.dart test/core/navigation/workspace_nav_config_test.dart test/core/navigation/workspace_navigation_widgets_test.dart`

---

## Phase 3 — Query-Backed Discount List

- [x] Pass status/scope/search to backend list query
- [x] Decide whether pagination is needed now or can stay deferred
- [x] Keep local client filtering only for transient UI polish, not as the primary source of truth
- [x] Update controller tests to verify query-backed filtering behavior

Output:

- discount list semantics are backend-driven instead of full-list local filtering

### Phase 3 result

What changed:

- [discount_list_controller.dart](/Users/mac/flutterProjects/modular/lib/features/discount/ui/viewmodels/discount_list_controller.dart)
  now treats backend list queries as the primary filter source

- status, scope, and search are now translated into backend query values:
  - `ALL -> all`
  - `ACTIVE -> active`
  - `INACTIVE -> inactive`
  - `ARCHIVED -> archived`
  - `ITEM -> item`
  - `BRANCH_WIDE -> branch_wide`

- filter behavior now works like this:
  - initial load fetches from backend using current filters
  - status/scope changes trigger immediate reload
  - search changes trigger a short debounce before reload
  - stale slower responses are ignored so the latest filter state wins

- local `filteredRules` state is still present only as transient UI polish while a new backend query is in flight
  - it is no longer the primary source of truth for list semantics

- pagination stays deferred for now
  - the list now sends backend filters
  - but we are still not surfacing pagination controls in the UI in this phase

- added focused controller verification in:
  - [discount_controllers_test.dart](/Users/mac/flutterProjects/modular/test/discount/discount_controllers_test.dart)
    - verifies query forwarding for status/scope/search
    - verifies search debounce before backend reload

Validation:

- `flutter analyze lib/features/discount/ui/viewmodels/discount_list_controller.dart test/discount/discount_controllers_test.dart test/discount/discount_api_test.dart`
- `flutter test test/discount/discount_controllers_test.dart test/discount/discount_api_test.dart test/discount/discount_repository_provider_test.dart test/discount/discount_pages_test.dart test/discount/discount_route_access_test.dart`

---

## Phase 4 — Sale Eligibility Resolution Foundation

- [x] Add discount eligibility resolve DTO/API/repository support for:
  - `POST /v0/discount/eligibility/resolve`
- [x] Define a sale-facing domain shape for resolved discount rules
- [x] Decide where this state lives in sale:
  - cart-local pricing model
  - checkout preview state
  - both
- [x] Thread current branch id + cart lines into resolution requests

Output:

- sale can ask backend which rules apply to the current cart

### Phase 4 result

What changed:

- added discount eligibility resolve support in the discount data layer:
  - [discount_eligibility.dart](/Users/mac/flutterProjects/modular/lib/features/discount/domain/models/discount_eligibility.dart)
  - [discount_eligibility_dto.dart](/Users/mac/flutterProjects/modular/lib/features/discount/data/dto/discount_eligibility_dto.dart)
  - [discount_repository.dart](/Users/mac/flutterProjects/modular/lib/features/discount/data/discount_repository.dart)
  - [discount_api.dart](/Users/mac/flutterProjects/modular/lib/features/discount/data/discount_api.dart)
  - [remote_discount_repository.dart](/Users/mac/flutterProjects/modular/lib/features/discount/data/remote_discount_repository.dart)
  - [mock_discount_repository.dart](/Users/mac/flutterProjects/modular/lib/features/discount/data/mock_discount_repository.dart)

- introduced a sale-facing resolved-discount domain seam:
  - [sale_resolved_discount.dart](/Users/mac/flutterProjects/modular/lib/features/sale/domain/models/sale_resolved_discount.dart)
  - [sale_discount_resolver.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_discount_resolver.dart)

- locked the state location for this phase:
  - resolved discount metadata now lives in cart-local sale state
  - [sale_cart_state.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_state.dart)
  - this phase does not yet change subtotal / tax / total math

- threaded branch context and cart lines into discount resolution from the cart notifier:
  - [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  - cart restore and cart line mutations now trigger background discount eligibility refresh
  - latest-request-wins protection avoids stale discount results overwriting newer cart state

- added focused coverage for the new seam:
  - [discount_api_test.dart](/Users/mac/flutterProjects/modular/test/discount/discount_api_test.dart)
  - [discount_controllers_test.dart](/Users/mac/flutterProjects/modular/test/discount/discount_controllers_test.dart)
  - [sale_discount_resolution_test.dart](/Users/mac/flutterProjects/modular/test/sale/sale_discount_resolution_test.dart)

Important scope boundary:

- sale can now ask backend which discount rules apply to the cart
- sale is not yet applying those rules to money math
- checkout snapshots and receipt/order propagation remain Phase 5 and Phase 6 work

Validation:

- `flutter analyze lib/features/discount/domain/models/discount_eligibility.dart lib/features/discount/data/dto/discount_eligibility_dto.dart lib/features/discount/data/discount_repository.dart lib/features/discount/data/discount_api.dart lib/features/discount/data/remote_discount_repository.dart lib/features/discount/data/mock_discount_repository.dart lib/features/sale/domain/models/sale_resolved_discount.dart lib/features/sale/data/sale_discount_resolver.dart lib/features/sale/ui/viewmodels/sale_cart_state.dart lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart test/discount/discount_api_test.dart test/discount/discount_controllers_test.dart test/sale/sale_discount_resolution_test.dart`
- `flutter test test/discount/discount_api_test.dart test/discount/discount_controllers_test.dart test/sale/sale_discount_resolution_test.dart test/sale/sale_cart_notifier_guard_test.dart test/sale/sale_cart_khqr_state_test.dart`

---

## Phase 5 — Cart Pricing + Snapshot Lock-In

- [x] Add discount-aware cart pricing model
  - line-level discount metadata
  - branch-wide discount metadata
  - computed discount totals
- [x] Apply stacking rules in sale pricing exactly as locked in the sale spec
- [x] Update cart summary UI to show discount truth
- [x] Build a sale snapshot payload that carries:
  - applied rule ids
  - names
  - percentages
  - line discount amounts
  - branch-wide discount amount
  - branch id used for resolution

Output:

- sale pricing becomes discount-aware before finalize

### Phase 5 result

What changed:

- added a shared cart-pricing seam in:
  - [sale_cart_pricing.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_pricing.dart)
  - item-level discounts now apply multiplicatively per line
  - branch-wide discounts now apply multiplicatively after line totals
  - VAT is now computed after discounts, not before

- wired cart pricing into the sale runtime in:
  - [sale_cart_viewmodel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart)
  - checkout, outage capture, offline cash replay, and cached receipt snapshot paths now all read from the same discount-aware pricing result

- extended cart line snapshot metadata in:
  - [sale_checkout_repository_contract.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_checkout_repository_contract.dart)
  - [sale_cart_payload_builder.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/viewmodels/sale_cart_payload_builder.dart)
  - line payload snapshots now carry:
    - line base amount
    - item discount amount
    - applied item rule ids / percentages / scopes
    - cart-level discount snapshot metadata
    - branch id used for discount resolution when available

- updated cart UI to show discount truth in:
  - [sale_cart_panel.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart)
  - [sale_cart_content.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart)
  - [sale_cart_item_row.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_item_row.dart)
  - [sale_cart_summary_row.dart](/Users/mac/flutterProjects/modular/lib/features/sale/ui/view/sale_cart/widgets/sale_cart_summary_row.dart)

- cart behavior now looks like this:
  - `Subtotal` shows pre-discount line sum
  - `Discount` shows total item + branch discount
  - line rows show the discounted amount and the struck-through original when a line discount applies
  - checkout gating uses the discount-aware grand total

Current contract limitation:

- the eligibility resolve endpoint still does not return discount rule names
- so the snapshot currently locks:
  - rule ids
  - percentages
  - scopes
- rule names still need backend support before they can be truthfully snapshotted

Validation:

- `flutter analyze lib/features/sale/ui/viewmodels/sale_cart_pricing.dart lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart lib/features/sale/ui/viewmodels/sale_cart_payload_builder.dart lib/features/sale/data/sale_checkout_repository_contract.dart lib/features/sale/ui/view/sale_cart/widgets/sale_cart_item_row.dart lib/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart lib/features/sale/ui/view/sale_cart/widgets/sale_cart_summary_row.dart lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart test/sale/sale_cart_pricing_test.dart test/sale/sale_cart_discount_summary_test.dart test/sale/sale_cart_content_khqr_test.dart`
- `flutter test test/sale/sale_cart_pricing_test.dart test/sale/sale_cart_discount_summary_test.dart test/sale/sale_cart_content_khqr_test.dart test/sale/sale_discount_resolution_test.dart test/sale/sale_offline_capture_test.dart test/sale/sale_offline_cash_queue_test.dart test/sale/sale_cart_readonly_test.dart test/sale/sale_cart_notifier_guard_test.dart test/sale/sale_cart_khqr_state_test.dart`

Known unrelated baseline:

- [sale_checkout_print_flow_test.dart](/Users/mac/flutterProjects/modular/test/sale/sale_checkout_print_flow_test.dart) still has the pre-existing async dispose/Dio failures and was not used as the gate for this phase

---

## Phase 6 — Checkout / Order / Receipt / Reporting Propagation

- [x] Remove placeholder `discountUsd: 0` payload assumptions where sale already knows real discount totals
- [x] Ensure finalized sale reads map discount values correctly
- [x] Ensure receipt surfaces show backend/finalized discount truth
- [x] Audit order/detail/reporting surfaces for discount fields already present in backend contracts
- [x] Keep historical sale records snapshot-driven and immutable

Output:

- discount truth survives beyond cart and appears consistently after finalize

### Phase 6 result

What is now wired:

- finalized sale DTO/domain mapping now preserves:
  - `discountUsd`
  - `discountKhr`
  - `vatUsd`
  - `vatKhr`
- canonical receipt mapping now preserves receipt-level `discountUsd`
- sale checkout receipt snapshots now store:
  - pre-discount subtotal
  - discount
  - tax
  - total
- receipt dialog and thermal receipt formatting now show:
  - `Subtotal`
  - `Discount`
  - `Tax`
  - `Total`

Scope boundary that remains:

- [sale_repository.dart](/Users/mac/flutterProjects/modular/lib/features/sale/data/sale_repository.dart)
  still sends `discountUsd: 0` / `vatUsd: 0` on open-ticket checkout
- that path only has current order-detail `lineSubtotal` truth today
- the order detail contract does not yet expose a finalized discount/tax split that frontend can trust for settlement payload decomposition

Assessment:

- direct checkout / finalized sale / receipt truth is now discount-aware
- open-ticket settlement remains a contract-limited seam, not a frontend math omission
- cash session and reporting surfaces already consume backend aggregated totals, so no additional discount-specific frontend rendering change was required in this phase

Validation:

- `flutter analyze lib/features/sale/domain/models/sale.dart lib/features/sale/data/dto/sale_dto.dart lib/features/sale/data/sale_checkout_repository_contract.dart lib/features/sale/data/sale_mappers.dart lib/core/printing/esc_pos_receipt_formatter.dart lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart lib/features/sale/ui/view/sale_cart/widgets/sale_cart_panel.dart lib/features/sale/data/mock_sale_repository.dart test/sale/sale_mapper_test.dart test/core/esc_pos_receipt_formatter_test.dart test/sale/sale_api_read_lane_test.dart`
- `flutter test test/sale/sale_mapper_test.dart test/core/esc_pos_receipt_formatter_test.dart test/sale/sale_api_read_lane_test.dart test/sale/sale_cart_pricing_test.dart test/sale/sale_cart_discount_summary_test.dart`

Known unrelated baseline:

- [sale_checkout_print_flow_test.dart](/Users/mac/flutterProjects/modular/test/sale/sale_checkout_print_flow_test.dart) still fails with the existing async `Ref`/`Dio` disposal issue in cash-session refresh; this phase did not change that behavior

---

## Phase 7 — Validation

- [ ] Run focused `flutter analyze` on discount + sale files touched
- [ ] Run focused widget/controller/repository tests
- [ ] Add at least one end-to-end discount sale scenario:
  - active item-level discount
  - optional branch-wide discount
  - sale finalize snapshot
  - receipt/order projection
- [ ] Manual QA:
  - admin creates rule
  - manager/cashier reads rule
  - sale cart reflects active rule
  - finalized sale keeps locked discount snapshot

Output:

- backend wiring and sale integration are proven, not assumed

---

## Tracking

| Phase | Status | Notes |
|---|---|---|
| 0 Contract Lock + Inventory | Completed | Runtime, routing, sale pricing, and downstream discount seams are now inventoried. |
| 1 Discount Management Runtime Cutover | Completed | Runtime now supports `DISCOUNT_REPOSITORY_MODE`, defaults to API, and the list envelope matches the current backend shape. |
| 2 Access / Routing Alignment | Completed | Manager/cashier can now open discount list/detail read-only; form route stays admin/owner only. |
| 3 Query-Backed Discount List | Completed | Status/scope/search now drive backend list queries; pagination remains deferred. |
| 4 Sale Eligibility Resolution Foundation | Completed | Sale now resolves eligible discount rules into cart-local state; pricing math still waits for Phase 5. |
| 5 Cart Pricing + Snapshot Lock-In | Completed | Cart totals, line rows, and sale snapshots are now discount-aware; rule names still need backend support. |
| 6 Checkout / Order / Receipt / Reporting Propagation | Completed | Finalized sale + receipt truth now preserve discount; open-ticket settlement still lacks a contract-backed discount/tax split. |
| 7 Validation | Proposed | Remote and sale-integration coverage still missing. |

---

## Recommended execution order

Do this in two waves:

### Wave A — Make the management module real

- Phase 1
- Phase 2
- Phase 3

This gives a trustworthy discount admin/read-only workspace first.

### Wave B — Make discounts affect sales for real

- Phase 4
- Phase 5
- Phase 6
- Phase 7

This is the pricing-critical half and should not be mixed casually with unrelated sale work.
