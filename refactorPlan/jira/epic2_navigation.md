# Epic 2 — Navigation UX Refactor (Reduce Kebab Navigation)

## Scope Statement (for Jira Epic)

- Replace **kebab-menu navigation** (hidden destinations) with **visible navigation** suitable for mobile and extensible to wide screens.
- Kebab menus remain for **secondary actions** only (filters, management actions, etc.), not for navigation between screens.
- Standard navigation primitives:
  - **Wide screens:** `NavigationRail` for global navigation (modules/destinations).
  - **Within a module/section (mobile):** `BottomNavigationBar` with an **indexed stack** for sub-pages that were previously hidden in kebab menus.

## Deliverable

- A clear navigation map and at least one implemented “pilot” area to prove the pattern (recommended pilot: Inventory).

## Reference Docs

- Navigation audit (kebab destinations): `docs/navigation/nav_audit.md`

---

## Jira Issues (Draft — copy/paste ready)

### EPIC — `[Navigation] Replace kebab navigation with visible navigation`

- **Goal:** Improve discoverability and reduce UX friction caused by hidden kebab navigation, while keeping actions discoverable.
- **Out of scope:** Redesign of business flows; widescreen layout work (handled by Epic 1) except minimal compatibility.

---

### Story 2.1 — `[Navigation] Audit kebab menu destinations and classify actions vs destinations`

- **Goal:** Produce a single source of truth mapping kebab items → routes, and decide what becomes visible navigation.
- **Scope:** All kebab menus used in the app (portal subpages included).
- **AC:**
  - Document exists listing each kebab menu item with: location (screen), label, route, and category (**destination** / **secondary action**).
  - Every current kebab “destination” has a target replacement (bottom nav / rail / inline button / other).
  - Team agrees on the classification (Reviewed status).
- **Tasks:**
  - Maintain `docs/navigation/nav_audit.md` as the mapping.
  - Inventory audit: Inventory home kebab items (Categories, Stock Items, Journal) captured.
  - Repeat for: Sale pages, Cash session pages, Reports, Staff pages, Policy pages (where applicable).
- **QA:** Verify every kebab item appears in the audit doc and still exists in UI.

---

### Spike 2.2 — `[Navigation] Decide information architecture for replacing kebab destinations`

- **Goal:** Decide what becomes a **module sub-page** (bottom nav) vs what stays a **secondary action**, and naming conventions.
- **Scope:** Mobile + wide (navigation primitives only; layout handled by Epic 1).
- **AC:**
  - Written decision: max bottom-nav item count per module and naming conventions.
  - Confirm which screens are “destinations” vs “actions” (e.g., Restock is an action, not a tab).
- **QA:** Decision reviewed by team.

---

### Story 2.3 — `[Inventory][Navigation] Replace Inventory kebab destinations with bottom navigation (pilot)`

- **Goal:** Inventory section becomes navigable without kebab menu.
- **Scope:** Inventory home + its current kebab destinations.
- **Bottom nav items (confirmed):**
  - Inventory
  - Stock Items
  - Categories
  - Journal
- **AC:**
  - Inventory pages reachable from bottom navigation without opening kebab:
    - Inventory Home
    - Stock Item Management
    - Category Management
    - Inventory Journal
  - Inventory kebab menu no longer contains navigation entries (may remain for secondary actions only).
  - Existing routes/deep links continue to work.
- **Tasks:**
  - Implement Inventory “navigation shell” (bottom nav + indexed stack).
  - Wire each tab to existing pages/routes (deep-linkable).
  - Remove navigation items from Inventory kebab menu.
- **QA:**
  - Navigate between bottom-nav items; state does not crash.
  - Back button returns to portal predictably.

**Implementation notes (for Jira story description)**
- Prefer `go_router` shell-style navigation so the bottom nav is visible across Inventory sub-pages:
  - Opening `AppRoute.inventoryCategories` should still show the Inventory bottom nav with “Categories” selected.
  - Opening `AppRoute.inventoryJournal` should still show the Inventory bottom nav with “Journal” selected.
- Restock remains an action (button), not a tab.

---

### Story 2.4 — `[Navigation] Standardize kebab menus for secondary actions only`

- **Goal:** Kebab becomes consistent across the app and stops being a navigation crutch.
- **Scope:** All modules.
- **AC:**
  - Kebab menus do not contain destinations that are available via bottom nav/rail/shell.
  - Kebab items are phrased as actions (verbs) and have consistent ordering.
- **Tasks:**
  - Define an ordering convention (e.g., View/Manage → Export → Dangerous last).
  - Update kebab menus module-by-module after each shell migration.

---

### Story 2.5 — `[Navigation] Prevent “back navigation bypass” of gating flows`

- **Goal:** Back navigation cannot land users in a state that bypasses required gating (e.g., cash session requirements).
- **Scope:** Flows that currently redirect/route based on state.
- **AC:**
  - From Cash Session screen, back returns to Portal (not to Sale).
  - From any gated flow, closing a prompt returns to safe landing.
- **QA:** Manual navigation tests across login → portal → sale/cash session flows.

---

### Story 2.6 — `[Navigation] Add wide-screen NavigationRail counterpart (post-pilot)`

- **Goal:** The same destinations are available on wide screens using NavigationRail.
- **Scope:** Inventory pilot first, then extend to other areas.
- **AC:**
  - On wide screens, rail appears for global navigation.
  - Inventory subpages still work (bottom nav remains the sub-navigation until a wide-screen variant is implemented).
- **Dependencies:** Epic 1 (responsive shell/breakpoints).

---

### Story 2.7 — `[Menu][Navigation] Replace Menu kebab destinations with visible navigation (Categories/Modifiers)`

- **Goal:** Menu management destinations are reachable without kebab menu.
- **Scope:** `MenuPage` kebab destinations:
  - Categories Management
  - Modifiers Management
- **AC:**
  - Categories and Modifiers management are reachable via visible navigation (no kebab required).
  - Kebab menu in Menu contains secondary actions only (or is removed if empty).
  - Navigation method is consistent (prefer `go_router` over raw `Navigator.push` where possible).
- **Tasks:**
  - Implement “Menu management nav” using a bottom-nav shell (mobile) with indexed stack.
  - Remove kebab destinations accordingly.
- **Dependencies:** Story 2.1 (audit) and Story 2.2 (IA decision).
