# Navigation Audit — Kebab Menu Destinations

Purpose: inventory of all navigation currently hidden inside kebab menus (`AppKebabMenu` / `PopupMenuButton`) so we can migrate **destinations** into visible navigation (mobile bottom nav, wide-screen rail) and keep kebab menus for **secondary actions** only.

---

## Definitions

- **Destination**: takes the user to another screen/page (a place you can “be”).
- **Secondary action**: performs an action on the current screen (filter/sort/export/manage state).

Rule for Epic 2: kebab menus should contain **secondary actions only**.

---

## Audit Method

This doc is derived from searching the Flutter codebase for:
- `AppKebabMenu(` / `KebabMenuItem(`
- `PopupMenuButton(` (direct usage)

---

## Findings

### Inventory — `lib/features/inventory/ui/view/inventory_home_page.dart`

| UI Location | Menu Label | Type | Navigation Target |
|---|---|---|---|
| AppBar kebab | Category management | Destination | `AppRoute.inventoryCategories.path` |
| AppBar kebab | Stock item management | Destination | `AppRoute.inventoryStockItems.path` |
| AppBar kebab | Inventory journal | Destination | `AppRoute.inventoryJournal.path` |

**Notes**
- Inventory also has an explicit action button “Restock” in `AppSearchAddBar` (this is an action, not a destination tab).

---

### Menu — `lib/features/menu/ui/view/menu_page.dart`

| UI Location | Menu Label | Type | Navigation Target |
|---|---|---|---|
| AppBar kebab | Categories Management | Destination | Push `CategoriesManagementPage` |
| AppBar kebab | Modifiers Management | Destination | Push `ModifiersManagementPage` |

**Notes**
- This screen uses `Navigator.push` with `MaterialPageRoute` instead of `go_router` routes.

---

## No Kebab Navigation Found (by search)

The following areas did not show `AppKebabMenu`/`PopupMenuButton` usage in code search at the time of writing:
- Sale
- Cash Session
- Reports
- Staff / Staff Attendance
- Policy

If you expect kebab navigation in these areas, it likely uses a different widget/pattern and should be added here once identified.

