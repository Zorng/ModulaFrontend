# Epic 1 — Responsive Widescreen (March)

## Outcome (for Jira Epic)

Deliver a **usable widescreen experience** (tablet/desktop web) by March, starting from the current mobile-first UI. This includes a consistent responsive layout system and applying it across **all existing features** so the app does not break or feel unfinished on wide screens.

## Why (context for team)

- Current UI is largely small-screen oriented and incomplete.
- Wide screen support is required on a deadline; without foundations we’ll patch per-page and create inconsistent UX and more tech debt.

## Scope

### In scope
- A documented breakpoint system and responsive layout rules.
- A reusable **responsive app shell** (mobile vs wide) that screens can plug into.
- Update all existing screens/features to avoid layout overflow, infinite constraints, and broken interactions on wide screens.
- Ensure navigation chrome works on wide screens (global `NavigationRail`) **as a layout concern** (Epic 2 covers the “kebab → visible nav” destination mapping/refactor).
- Mobile-web UX for navigation chrome (hide/show bottom navigation while scrolling).

### Out of scope
- Full UX redesign of each module.
- New feature delivery unrelated to layout.
- Printing work (separate epic).
- Animation/polish (separate epic).

## References

- Breakpoints notes: `docs/responsive_breakpoints.md`

---

## Jira Issues (Draft — copy/paste ready)

### EPIC — `[Responsive] Widescreen support for March`

- **Goal:** App is usable on tablet/desktop with no layout exceptions and clear navigation.

---

### Story 1.1 — `[Responsive] Define breakpoint system and layout rules`

- **Goal:** Team has one shared standard for mobile/tablet/desktop behavior.
- **AC:**
  - Breakpoints documented (mobile/tablet/desktop) and referenced by code.
  - Rules documented for: max content width, padding, and when to switch nav patterns.
- **Tasks:**
  - Write/confirm breakpoints in `docs/responsive_breakpoints.md`.
  - Add a small helper (e.g., `ResponsiveBreakpoints`) used across screens.
- **QA:** Resize browser; breakpoints match doc.

---

### Story 1.2 — `[Responsive] Implement reusable responsive shell (mobile vs wide)`

- **Goal:** Provide a shared scaffold that prevents per-page reinvention and keeps layout consistent.
- **Scope:** Layout only (slots for app bar/nav/body).
- **AC:**
  - Mobile layout uses standard app bar + body; wide layout adds rail/sidebar region.
  - No “BoxConstraints forces an infinite width” errors when used correctly.
  - At least one pilot screen uses the shell without regressions.
- **Tasks:**
  - Implement `ResponsiveShell` widget.
  - Add a demo/pilot usage on a low-risk screen (Portal or Inventory).
- **QA:** Confirm no overflow/infinite constraints on pilot screen.

---

### Story 1.3 — `[Responsive][Navigation] Global NavigationRail on wide screens`

- **Goal:** Wide screens use a single shared `NavigationRail` for global navigation (no sub-rails).
- **Scope:** Layout chrome only; destinations and labels are handled in Epic 2.
- **AC:**
  - On wide screens, `NavigationRail` is visible and usable.
  - No sub-rail is introduced.
  - Bottom navigation on wide screens **does not hide** (rail + bottom nav coexist).
- **QA:** Resize to wide width and verify rail appears; no overlap/overflow.

---

### Story 1.4 — `[Responsive][Navigation] Hide bottom navigation on scroll (mobile web)`

- **Goal:** On mobile web, bottom navigation hides while scrolling content to maximize vertical space.
- **AC:**
  - Scrolling down hides bottom nav; scrolling up reveals it.
  - Does not block scroll performance or tap interactions.
  - Works consistently on key list pages (menu lists, inventory lists, report lists).
  - This behavior applies to **mobile web viewports only**; wide screens keep bottom nav visible.
- **QA:** Manual scroll test on mobile web viewport.

---

### Story 1.5 — `[Responsive][Portal] Make portals usable on wide screens`

- **Goal:** Admin/Cashier portals render correctly and remain navigable on wide screens.
- **AC:**
  - No layout overflow exceptions.
  - Content does not stretch unreadably (max width constraints applied).
  - Tap targets remain accessible.
- **QA:** Test at common desktop widths and tablet widths.

---

### Story 1.6 — `[Responsive][Sale] Sale browse + item detail + cart usable on wide screens`

- **Goal:** Sale experience works on wide screens without broken layouts.
- **AC:**
  - Sale page renders menu grid/list appropriately (no empty/infinite width issues).
  - Sale item detail layout works at wide widths.
  - Cart page layout works at wide widths.
- **QA:** Manual flow: open sale → open item → open cart.

---

### Story 1.7 — `[Responsive][Sale] Checkout flow usable on wide screens`

- **Goal:** Checkout actions (payment selection, tender input, confirmation) are usable and readable on wide screens.
- **Scope:** Sale cart checkout UI and any dialogs/bottom-sheets used by checkout.
- **AC:**
  - Checkout UI does not overflow on wide screens.
  - Controls have reasonable max widths and do not stretch awkwardly.
  - Critical actions (confirm/cancel/back) remain accessible.
- **QA:** Manual flow: add item → open cart → checkout on wide screen.

---

### Story 1.8 — `[Responsive][Inventory] Inventory pages usable on wide screens`

- **Goal:** Inventory home, stock item management/detail, restock, journal pages render well.
- **AC:** No overflow; forms readable; lists not overly stretched.

---

### Story 1.9 — `[Responsive][Cash/Reports] Cash session + reports usable on wide screens`

- **Goal:** Cash session screens and X/Z report pages render correctly on wide screens.
- **AC:** No overflow; tables/cards readable.

---

### Story 1.10 — `[Responsive][Menu] Menu pages usable on wide screens`

- **Goal:** Menu browse/management screens are usable on wide screens.
- **Scope:** Menu page, category management, modifier management, item form/detail pages.
- **AC:** No overflow; forms readable; lists/grids have sensible max widths.
- **QA:** Open menu → open item form/detail → open categories/modifiers.

---

### Story 1.11 — `[Responsive][Policy] Policy pages usable on wide screens`

- **Goal:** Policy UI is readable and usable on wide screens.
- **Scope:** Policy list page and policy detail pages (if any).
- **AC:** No overflow; toggles/forms aligned and not stretched.
- **QA:** Open policy page, interact with sections at wide width.

---

### Story 1.12 — `[Responsive][Staff] Staff management pages usable on wide screens`

- **Goal:** Staff list and staff detail pages are usable on wide screens.
- **Scope:** Staff list, staff detail (including shift info panel), and any “coming soon” add-new page.
- **AC:** No overflow; list/detail layout readable; shift info table scales correctly.
- **QA:** Open staff list → open staff detail on wide width.

---

### Story 1.13 — `[Responsive][Attendance] Attendance pages usable on wide screens`

- **Goal:** Attendance (cashier) and Attendance Management (admin/manager) are usable on wide screens.
- **Scope:** Attendance page (check/history) and attendance management list/detail views.
- **AC:** No overflow; date pickers and lists/cards render correctly.
- **QA:** Open attendance pages on wide width and interact with filters.

---

### Story 1.14 — `[Responsive] Add a “layout regression checklist” and enforce it in PR reviews`

- **Goal:** Prevent reintroducing overflow/infinite constraint issues.
- **AC:**
  - Checklist exists (screens to quickly resize/test).
  - New UI changes mention which widths were checked.
