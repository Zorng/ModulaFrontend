# Navigation Workspace System

This document captures the updated navigation model as a single system reference.

## Purpose
- Document the end-to-end navigation flow after auth context selection.
- Define workspace modes and feature visibility.
- Record key navigation changes from the previous model.

## Scope
- Auth -> tenant -> branch -> workspace entry flow.
- Wide-screen rail behavior and non-wide portal behavior.
- Workspace-based feature access (instead of branch switching from rail/portal).

## What Changed
1. Branch selection is now a gateway step, not an in-workspace control.
2. Rail and portal must not contain branch selectors/dropdowns.
3. Admin/Owner can enter two workspace modes:
   - Global Workspace
   - Branch Workspace (Management and POS mode)
4. Non-Admin/Owner enters Branch Workspace in POS mode directly.
5. Branch Subscription is introduced as a new branch-management destination.

## Current Roles (Implemented Baseline)

Role normalization is defined in:
- `lib/features/auth/domain/auth_role.dart`

| Raw role value | Normalized role | Notes |
|---|---|---|
| `owner` | `AuthRole.owner` | Tenant owner |
| `tenant_owner` | `AuthRole.owner` | Owner alias |
| `admin` | `AuthRole.admin` | Admin |
| `manager` | `AuthRole.manager` | Manager |
| `cashier` | `AuthRole.cashier` | Cashier |
| any other value / empty | `AuthRole.unknown` | Unknown fallback |

Access semantics currently applied:
- Admin-or-owner permissions are evaluated with normalized role (`admin` or `owner`).
- Cashier-only checks use normalized `cashier`.
- Manager-only checks use normalized `manager`.
- Unknown role is treated as non-privileged.

## End-to-End Flow
1. User logs in.
2. User selects tenant.
3. User selects branch (or global management entry) from branch selection page.
4. App resolves workspace context and renders navigation for that workspace.

## Workspace Model

| Workspace | Entry rule | Scope | Feature set |
|---|---|---|---|
| Global Workspace | Admin/Owner taps Global Management | Tenant-level | Menu, Inventory, Staff |
| Branch Workspace (Management) | Admin/Owner taps a branch | Active branch | Policy, Branch Subscription, POS Mode entry |
| Branch Workspace (POS Mode) | Admin/Owner chooses POS Mode, or Non-Admin/Owner taps a branch | Active branch + user context | Admin/Owner: Sale, Cash Session. Non-Admin/Owner: Sale, Cash Session, Attendance |

## Navigation Surfaces
- Wide (`>= 1024`): `NavigationRail` in `AppScaffoldShell`.
- Non-wide (`< 1024`): Portal launcher cards.
- Both surfaces must use the same workspace-aware destination map.
- Branch context is display-only inside workspace chrome; it is not editable there.

## Routing Notes
- Routes remain canonical and role-agnostic (`/sale`, `/menu`, `/inventory`, etc.).
- Branch Subscription placeholder route exists:
  - `AppRoute.branchSubscription`
  - path: `/branches/subscription`
- Branch selection remains the only place where branch context is chosen.

## State Model (Navigation-Relevant)
- Auth session state: who the user is and token/context requirements.
- Active branch context: selected from branch selection flow.
- Workspace context:
  - `workspaceScope`: `global | branch`
  - `workspaceMode`: `management | pos`
  - `activeBranchId`: required for branch workspace
- Phase 0 contract artifacts:
  - `lib/features/auth/domain/auth_role.dart`
  - `lib/features/auth/domain/workspace_context.dart`

## Implementation Status Snapshot
- Implemented:
  - Branch Subscription placeholder page and route wiring.
  - Workspace context provider and branch-selection workspace assignment wiring.
  - Branch context lock from branch-selection flow (branch override writes are ignored when workspace context is active).
  - Shared workspace navigation config for rail + portal.
  - Branch selector controls removed from rail and portal surfaces.
  - Workspace-aware router guards (`global` vs `branch` scope + branch-context-required checks).
  - Branch-context guard utility with user-safe redirect reason (`/select-branch?reason=branch_context_required`).
  - Workspace-aware hydration branch resolution and reload/reset handling on workspace transitions.
  - Unit/widget/router tests for navigation workspace behavior.

## Related Docs
- `integration/refactorPlan/navigation_rail_portal_part1_current_flow.md`
- `integration/refactorPlan/navigation_rail_portal_part2_updated_workspace_refactor_plan.md`
- `handbook/architecture/navigation.md`
- `handbook/architecture/overview.md`
