# Epic 2 — Navigation UX Refactor (Reduce Kebab Navigation)

## Scope Statement (for Jira Epic)

- Replace **kebab-menu navigation** (hidden destinations) with **visible navigation** suitable for mobile and extensible to wide screens.
- Kebab menus remain for **secondary actions** only (filters, management actions, etc.), not for navigation between screens.
- Bottom navigation is **not** “primary modules”; it is for destinations that are currently accessible via kebab menus.

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

### Spike 2.2 — `[Navigation] Decide bottom-nav information architecture for “kebab destinations”`

- **Goal:** Decide how many tabs per area, naming, and iconography, without overloading bottom nav.
- **Scope:** Mobile navigation only.
- **AC:**
  - Written decision: max tab count, tab labels, and what becomes “More” vs “Action”.
  - Confirm which screens are “destinations” vs “actions” (e.g., Restock is an action, not a destination tab).
- **QA:** Decision reviewed by team.

---

### Story 2.3 — `[Inventory][Navigation] Replace Inventory kebab destinations with bottom navigation (pilot)`

- **Goal:** Inventory section becomes navigable without kebab menu.
- **Scope:** Inventory home + its current kebab destinations.
- **Tabs (confirmed):**
  - Inventory
  - Stock Items
  - Categories
  - Journal
- **AC:**
  - Inventory pages reachable from bottom nav without opening kebab:
    - Inventory Home
    - Stock Item Management
    - Category Management
    - Inventory Journal
  - Inventory kebab menu no longer contains navigation entries (may remain for secondary actions only).
  - Existing routes/deep links continue to work.
- **Tasks:**
  - Implement Inventory “navigation shell” for mobile (BottomNavigationBar).
  - Wire each tab to existing pages/routes.
  - Remove navigation items from Inventory kebab menu.
- **QA:**
  - Navigate between tabs; state does not crash.
  - Back button returns to portal predictably.

**Implementation notes (for Jira story description)**
- Prefer `go_router` shell-style navigation so the bottom nav is visible across Inventory tabs:
  - Opening `AppRoute.inventoryCategories` should still show Inventory bottom nav with “Categories” selected.
  - Opening `AppRoute.inventoryJournal` should still show Inventory bottom nav with “Journal” selected.
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
  - On wide screens, rail appears and bottom nav is replaced/hidden.
  - Same destinations as mobile bottom nav are accessible.
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
  - Decide “Menu management nav” pattern (bottom nav vs segmented buttons vs tabs) for mobile.
  - Implement the navigation and remove kebab destinations accordingly.
- **Dependencies:** Story 2.1 (audit) and Story 2.2 (IA decision).

