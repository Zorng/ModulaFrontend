# Navigation Overhaul – Part 2 (Detail Modal Standardization)

Goal: standardize detail presentation across breakpoints to eliminate inconsistent back buttons.

## Rule (locked)
- **Quick‑view detail (read‑only)** → modal
  - Mobile: bottom sheet
  - Wide: side sheet / modal
- **Workflow/detail with edits or multi‑step** → full‑page
  - Back button **required**
  - Back returns to parent tab/root (no back)

## Scope (impact scan)
- Identify all detail pages and classify (quick‑view vs workflow)
- Update routing behavior for quick‑view pages (modal presentation)
- Remove back buttons from pages that become modal‑only
- Ensure URL behavior for modal entry is defined (optional deep‑link handling)
- Update navigation standards doc

---

## Phase 0 — Inventory & Classification
- [x] List all detail pages by feature
- [x] Tag each as **Quick‑view** or **Workflow**
- [x] Note any hybrid pages (view + edit in same screen)

**Output:** detail inventory table with classification

### Detail inventory (by feature)

| Feature | Page (route) | Current | Target | Notes |
|---|---|---|---|---|
| Auth | Account (`/account`) | Full page | Workflow | Profile/manage account |
| Auth | Settings (`/settings`) | Full page | Workflow | Settings management |
| Menu | View menu item (`/menu/items/view`) | Full page | Quick‑view | Has “Edit” action → opens form |
| Menu | View modifier group (`/menu/modifiers/view`) | Full page | Quick‑view | Has “Edit” action → opens form |
| Menu | Menu item form (`/menu/items/form`) | Full page | Workflow | Create/edit |
| Menu | Add category (`/menu/categories/add`) | Full page | Workflow | Create |
| Menu | Edit category (`/menu/categories/edit`) | Full page | Workflow | Edit |
| Menu | Add modifier group (`/menu/modifiers/add`) | Full page | Workflow | Create |
| Menu | Edit modifier group (`/menu/modifiers/edit`) | Full page | Workflow | Edit |
| Inventory | Stock item detail (`/inventory/detail`) | Full page | Workflow | Edit + image upload |
| Inventory | Restock item (`/inventory/restock`) | Full page | Workflow | Action flow |
| Inventory | Adjust stock (`/inventory/adjust`) | Full page | Workflow | Action flow |
| Inventory | Add stock item (`/inventory/add-item`) | Full page | Workflow | Create |
| Inventory | Journal detail (`/inventory/journal/detail`) | Full page | Quick‑view | Read‑only day entries |
| Sale | Sale item detail (`/sale/item`) | Full page | Workflow | Add to cart action |
| Sale | Order detail (`/sale/orders/detail`) | Full page | Quick‑view | Read‑only summary |
| Sale | Cart detail (`/sale/carts/detail`) | Full page | Quick‑view | Read‑only cart snapshot |
| Staff | Staff detail (`/staff/detail`) | Full page | Workflow | Has “Edit” action |
| Staff | Staff form (`/staff/form`) | Full page | Workflow | Create/edit |
| Staff | Staff add placeholder (`/staff/add`) | Full page | Workflow | Placeholder full page |
| Policy | VAT policy detail (`/policy/vat`) | Full page | Workflow | Editable |
| Policy | Policy item detail (`/policy/item`) | Full page | Workflow | Editable |
| Reports | X Report (`/reports/x`) | Full page | N/A | Main list (expandable cards) |
| Reports | Z Report (`/reports/z`) | Full page | N/A | Main generate view |
| Cash session | Cash session (`/cash/session`) | Full page | N/A | Main flow |

---

## Phase 1 — Modal Infrastructure (if needed)
- [x] Confirm existing modal/sheet helpers (if any)
- [x] Decide standard widgets:
  - Mobile: `showModalBottomSheet`
  - Wide: `showDialog` or side sheet (preferred)
- [x] Define a small wrapper helper for consistency (optional)

**Output:** modal standard decided + helper (if needed)

---

## Phase 2 — Convert Quick‑view Pages
- [x] Replace navigation to quick‑view pages with modal presentation
- [x] Remove AppBar/back from modal content
- [x] Ensure close action is explicit

**Output:** quick‑view pages open as modal on mobile + wide

---

## Phase 3 — Workflow Pages
- [x] Verify workflow pages remain full‑page
- [x] Ensure consistent back behavior

**Output:** back buttons only on full‑page workflows

---

## Phase 4 — Docs + QA
- [ ] Update navigation standards doc
- [ ] Add rule to non‑negotiables (if needed)
- [ ] Manual QA checklist across breakpoints

---

## Tracking
| Phase | Status | Notes |
|---|---|---|
| 0 | Complete | Detail inventory + classification captured |
| 1 | Complete | Responsive detail modal helper added |
| 2 | Complete | Quick‑view pages open as modal on mobile + wide |
| 3 | Complete | Workflow pages remain full‑page; back relies on standard AppBar behavior |
| 4 | Not started |  |
