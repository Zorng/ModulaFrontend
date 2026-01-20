# Debloat Refactor Tracking

This file tracks:
- Which pages/screens have been de-bloated (and what remains)
- Widgets extracted during debloat work
- Candidates to promote/dedupe later

It is a refactor-time working document (not long-lived handbook documentation).

Goal:
- Reduce widget bloat and duplication
- Make common UI primitives discoverable
- Keep page code readable (composition-first)

## Rules of thumb
- If a widget is used by **2+ features**, promote it to `lib/core/widgets/` (pick the correct subfolder).
- If it is used by **only one feature**, keep it feature-local:
  - shared across pages → `lib/features/<feature>/ui/components/`
  - used only by one page → `lib/features/<feature>/ui/view/<page>/widgets/`
- If two people build similar widgets in parallel, keep them feature-local and create a Jira ticket to dedupe later.

## How to use this file
1) When you create a widget that “feels reusable”, add it to this list as **Candidate**.
2) If another feature starts using it, either:
   - promote it to core, or
   - file a Jira “dedupe + promote” task if timing is risky.
3) When promoted, update `Status` and `Promoted To`.

## Page debloat status

| Feature | Page | Current Path | Status | Notes |
|---|---|---|---|---|
| Auth | Account | `lib/features/auth/ui/view/account/account_page.dart` | De-bloated | Page-local widgets under `lib/features/auth/ui/view/account/widgets/` |
| Auth | Admin portal | `lib/features/auth/ui/portals/admin_portal.dart` | De-bloated | Extracted sections under `lib/features/auth/ui/portals/admin/widgets/` |
| Auth | Tenant selection | `lib/features/auth/ui/view/tenant_selection/tenant_selection_page.dart` | De-bloated | Page-local widgets under `lib/features/auth/ui/view/tenant_selection/widgets/` |
| Cash session | X report | `lib/features/cash_session/ui/view/x_report/x_report_page.dart` | De-bloated | Page-local widgets under `lib/features/cash_session/ui/view/x_report/widgets/` |
| Cash session | Z report | `lib/features/cash_session/ui/view/z_report/z_report_page.dart` | De-bloated | Page-local widgets under `lib/features/cash_session/ui/view/z_report/widgets/` |
| Inventory | Inventory home | `lib/features/inventory/ui/view/inventory_home/inventory_home_page.dart` | De-bloated | Moved into page folder |
| Inventory | Stock items | `lib/features/inventory/ui/view/inventory_stock_items/inventory_stock_items_page.dart` | De-bloated | Extracted card + image widgets; uses `ProductImage` |
| Inventory | Inventory categories | `lib/features/inventory/ui/view/category_management/category_management_page.dart` | De-bloated | Extracted category tile widget |
| Inventory | Inventory journal (main) | `lib/features/inventory/ui/view/inventory_journal/inventory_journal_page.dart` | De-bloated | Extracted group/date widgets + models |
| Inventory | Inventory journal (detail) | `lib/features/inventory/ui/view/inventory_journal_detail/inventory_journal_detail_page.dart` | De-bloated | Extracted search + entry card widgets |
| Inventory | Add stock item | `lib/features/inventory/ui/view/add_stock_item/add_stock_item_page.dart` | De-bloated | Uses `ProductImagePicker` via `UploadImageTile`; supports clear-local selection |
| Inventory | Stock item detail | `lib/features/inventory/ui/view/stock_item_detail/stock_item_detail_page.dart` | De-bloated | Extracted image upload tile; branch assignment moved to `ui/components/` |
| Inventory | Restock stock item | `lib/features/inventory/ui/view/restock_stock_item/restock_stock_item_page.dart` | De-bloated | Extracted branch selector/autocomplete/quantity/summary widgets |
| Inventory | Adjust quantity | `lib/features/inventory/ui/view/stock_adjust_quantity/stock_adjust_quantity_page.dart` | De-bloated | Extracted inputs + batch list into page-local widgets |
| Menu | Categories management | `lib/features/menu/ui/view/categories_management/categories_management_page.dart` | De-bloated | Extracted tile + edit sheet widgets |
| Menu | Modifiers management | `lib/features/menu/ui/view/modifiers_management/modifiers_management_page.dart` | De-bloated | Extracted list tile widget |
| Menu | Add category | `lib/features/menu/ui/view/add_category/add_category_page.dart` | De-bloated | Moved into page folder; uses `MenuFormFieldLabel` |
| Menu | Edit category | `lib/features/menu/ui/view/edit_category/edit_category_page.dart` | De-bloated | Moved into page folder; uses `MenuFormFieldLabel` |
| Menu | Add modifier group | `lib/features/menu/ui/view/add_modifier_group/add_modifier_group_page.dart` | De-bloated | Extracted option row widget + model; uses `MenuFormFieldLabel` |
| Menu | Edit modifier group | `lib/features/menu/ui/view/edit_modifier_group/edit_modifier_group_page.dart` | De-bloated | Extracted default selector + option row widgets; uses `MenuFormFieldLabel` |
| Menu | View menu item | `lib/features/menu/ui/view/view_menu_item/view_menu_item_page.dart` | De-bloated | Moved into page folder; extracted utils |
| Menu | Menu item form | `lib/features/menu/ui/view/menu_item_form/menu_item_form_page.dart` | De-bloated | Extracted image picker + selection chips + bottom sheet util; removed `dart:io` dependency |
| Menu | View modifier group | `lib/features/menu/ui/view/view_modifier_group/view_modifier_group_page.dart` | De-bloated | Extracted option row widget (still uses `Navigator` for edit) |
| Sale | Cart | `lib/features/sale/ui/view/sale_cart/sale_cart_page.dart` | De-bloated | Page-local widgets under `lib/features/sale/ui/view/sale_cart/widgets/` |
| Sale | Item detail | `lib/features/sale/ui/view/sale_item_detail/sale_item_detail_page.dart` | De-bloated | Page-local widgets under `lib/features/sale/ui/view/sale_item_detail/widgets/` |
| Sale | Orders | `lib/features/sale/ui/view/order/order_page.dart` | De-bloated | Page-local widgets under `lib/features/sale/ui/view/order/widgets/` |
| Sale | Order detail | `lib/features/sale/ui/view/order_detail/order_detail_page.dart` | De-bloated | Page-local widgets under `lib/features/sale/ui/view/order_detail/widgets/` |
| Sale | Sale (menu) | `lib/features/sale/ui/view/sale/sale_page.dart` | De-bloated | Page-local widgets under `lib/features/sale/ui/view/sale/widgets/` |
| Sale | View carts | `lib/features/sale/ui/view/view_carts/view_carts_page.dart` | De-bloated | Page-local widgets under `lib/features/sale/ui/view/view_carts/widgets/` |
| Sale | View cart detail | `lib/features/sale/ui/view/view_cart_detail/view_cart_detail_page.dart` | De-bloated | Moved into its own page folder; extracted status chip + line tile widgets |
| Policy | Policy | `lib/features/policy/ui/view/policy/policy_page.dart` | De-bloated | Moved into page folder |
| Policy | Policy detail | `lib/features/policy/ui/view/policy_detail/policy_detail_page.dart` | De-bloated | Moved into page folder |
| Policy | VAT detail | `lib/features/policy/ui/view/vat_policy_detail/vat_policy_detail_page.dart` | De-bloated | Extracted rate sheet into page-local widget |
| Policy | Inventory policy detail | `lib/features/policy/ui/view/inventory_policy_detail/inventory_policy_detail_page.dart` | De-bloated | Moved into page folder |
| Policy | Early check-in detail | `lib/features/policy/ui/view/early_check_in_detail/early_check_in_detail_page.dart` | De-bloated | Moved into page folder |
| Staff | Staff form | `lib/features/staff/ui/view/staff_form/staff_form_page.dart` | De-bloated | Page-local widgets under `lib/features/staff/ui/view/staff_form/widgets/` |
| Staff attendance | Attendance | `lib/features/staff_attendance/ui/view/attendance/attendance_page.dart` | De-bloated | Extracted tab switcher + shift/today/history cards |
| Staff attendance | Attendance management | `lib/features/staff_attendance/ui/view/attendance_management/attendance_management_page.dart` | De-bloated | Extracted date picker row + record card widgets |
| Menu | Menu (main) | `lib/features/menu/ui/view/menu/menu_page.dart` | De-bloated | Page-local widgets under `lib/features/menu/ui/view/menu/widgets/` |

## Widget candidates (from debloat work)

| Widget | Current Path | Used In Features | Candidate Category | Status | Promoted To | Notes / Jira |
|---|---|---:|---|---|---|---|
| `AppSearchAddBar` | `lib/core/widgets/forms/app_search_add_bar.dart` | 3 | `forms/` | Promoted | `lib/core/widgets/forms/app_search_add_bar.dart` | Shared “search + add new” bar (inventory + menu + staff) |
| `ProductImage` | `lib/core/widgets/media/product_image.dart` | 3 | `media/` | Promoted | `lib/core/widgets/media/product_image.dart` | Standard “image + placeholder” (inventory + menu + sale) |
| `ProductImagePicker` | `lib/core/widgets/media/product_image_picker.dart` | 2 | `media/` | Promoted | `lib/core/widgets/media/product_image_picker.dart` | Standard image picking UX (menu + inventory) |
| `PolicyDetailControls` | `lib/features/policy/ui/widgets/policy_detail_controls.dart` | 3 | `layout/` | Candidate |  | Cross-feature use (auth + common + policy) → consider promoting to `lib/core/widgets/` |
| `DashedBorderPainter` | `lib/core/widgets/display/dashed_border_painter.dart` | 2 | `display/` | Promoted | `lib/core/widgets/display/dashed_border_painter.dart` | Shared dashed placeholder painter (inventory + menu) |
| `MenuItemCard` | `lib/core/widgets/display/menu_item_card.dart` | 2 | `display/` | Promoted | `lib/core/widgets/display/menu_item_card.dart` | Shared item card base (menu + sale) |
| `AppBackButton` | `lib/core/widgets/navigation/app_back_button.dart` | 2 | `navigation/` | Promoted | `lib/core/widgets/navigation/app_back_button.dart` | Shared back button (policy + sale) |
| `AppKebabMenu` | `lib/core/widgets/navigation/app_kebab_menu.dart` | 2 | `navigation/` | Promoted | `lib/core/widgets/navigation/app_kebab_menu.dart` | Shared kebab menu trigger (inventory + menu) |
| `AdminHomeContent` | `lib/features/auth/ui/portals/admin/widgets/admin_home_content.dart` | 1 | `layout/` | Candidate |  | Admin portal: extracted page section (not a promotion candidate yet) |
| `PortalPlaceholderCard` | `lib/features/auth/ui/portals/admin/widgets/portal_placeholder_card.dart` | 1 | `display/` | Candidate |  | Admin portal: “coming soon” placeholder card (consider dedupe with cashier portal placeholders) |
| `SaleShortcutCard` | `lib/features/auth/ui/portals/admin/widgets/sale_shortcut_card.dart` | 1 | `display/` | Candidate |  | Admin portal: quick sale shortcut card (may merge with shared portal feature cards) |
| `StaffProfileAvatar` | `lib/features/staff/ui/view/staff_form/widgets/staff_profile_avatar.dart` | 1 | `display/` | Candidate |  | Staff form: extracted avatar (keep page-local unless reused) |
| `StaffScheduleSection` | `lib/features/staff/ui/view/staff_form/widgets/staff_schedule_section.dart` | 1 | `forms/` | Candidate |  | Staff form: schedule editor section (keep page-local unless reused) |
| `StaffFormActions` | `lib/features/staff/ui/view/staff_form/widgets/staff_form_actions.dart` | 1 | `layout/` | Candidate |  | Staff form: action buttons row (keep page-local unless reused) |
| `SaleCartBottomBar` | `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_bottom_bar.dart` | 1 | `layout/` | Candidate |  | Sale cart: “total + CTA” bottom bar |
| `SaleCartReadOnlyBanner` | `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_readonly_banner.dart` | 1 | `feedback/` | Candidate |  | Sale cart: read-only banner + action |
| `SaleOrderTypeSelector` | `lib/features/sale/ui/view/sale_cart/widgets/sale_order_type_selector.dart` | 1 | `forms/` | Candidate |  | Sale cart: order type selector chips |
| `SaleCartContent` | `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart` | 1 | `display/` | Candidate |  | Sale cart: cart lines + payments UI (likely stays feature-local) |
| `SaleItemDetailBottomBar` | `lib/features/sale/ui/view/sale_item_detail/widgets/sale_item_detail_bottom_bar.dart` | 1 | `layout/` | Candidate |  | Sale item detail: “total + qty + Add Item” bottom bar |
| `QuantityStepper` | `lib/features/sale/ui/components/quantity_stepper.dart` | 1 | `forms/` | Candidate |  | Used in sale cart lines + sale item detail |
| `SaleItemDetailImage` | `lib/features/sale/ui/view/sale_item_detail/widgets/sale_item_detail_image.dart` | 1 | `media/` | Candidate |  | Sale item detail: image + placeholder |
| `SaleItemModifierGroupSection` | `lib/features/sale/ui/view/sale_item_detail/widgets/sale_item_modifier_group_section.dart` | 1 | `forms/` | Candidate |  | Sale item detail: modifier selection section |
| `MenuFormFieldLabel` | `lib/features/menu/ui/components/menu_form_field_label.dart` | 1 | `forms/` | Candidate |  | Menu forms: standard label + helper text |
| `PolicySection` | `lib/features/policy/ui/widgets/policy_section.dart` | 1 | `layout/` | Candidate |  | Policy: section layout wrapper |
| `CashSessionBottomActionArea` | `lib/features/cash_session/ui/widgets/cash_session_bottom_action_area.dart` | 1 | `layout/` | Candidate |  | Cash session: sticky bottom CTA area |
| `CashSessionDetailsCard` | `lib/features/cash_session/ui/widgets/cash_session_details_card.dart` | 1 | `display/` | Candidate |  | Cash session: summary card |
| `StartSessionModal` | `lib/features/cash_session/ui/widgets/start_session_modal.dart` | 1 | `dialogs/` | Candidate |  | Cash session: start session modal |
| `CloseSessionModal` | `lib/features/cash_session/ui/widgets/close_session_modal.dart` | 1 | `dialogs/` | Candidate |  | Cash session: close session modal |
| `FormTextField` | `lib/features/staff/ui/widgets/form_text_field.dart` | 1 | `forms/` | Candidate |  | If reused outside staff, promote to core |
| `FormDropdownField` | `lib/features/staff/ui/widgets/form_dropdown_field.dart` | 1 | `forms/` | Candidate |  | If reused outside staff, promote to core |
| `TimePickerDropdown` | `lib/features/staff/ui/widgets/time_picker_dropdown.dart` | 1 | `forms/` | Candidate |  | Staff: time picker dropdown |
| `WorkingDaysDropdown` | `lib/features/staff/ui/widgets/working_days_dropdown.dart` | 1 | `forms/` | Candidate |  | Staff: working days selection |
| `StaffListCard` | `lib/features/staff/ui/widgets/staff_list_card.dart` | 1 | `display/` | Candidate |  | Staff list: card tile |
| `CustomCupertinoListTile` | `lib/features/staff/ui/widgets/custom_cupertino_list_tile.dart` | 1 | `display/` | Candidate |  | Staff: reusable list tile style |
| `AppFilterDropdown` | `lib/features/staff/ui/widgets/app_filter_dropdown.dart` | 1 | `forms/` | Candidate |  | Might be reusable for inventory/report filters |
| `InventoryItemCard` | `lib/features/inventory/ui/widgets/inventory_item_card.dart` | 1 | `display/` | Candidate |  | Inventory: stock item card (older inventory flow) |
| `InventorySectionCard` | `lib/features/inventory/ui/widgets/inventory_section_card.dart` | 1 | `layout/` | Candidate |  | Compare with `lib/core/widgets/layout/app_section_card.dart` |
| `InventoryDropdown` | `lib/features/inventory/ui/widgets/inventory_dropdown.dart` | 1 | `forms/` | Candidate |  | Likely becomes shared dropdown pattern |
| `BranchAssignmentCard` | `lib/features/inventory/ui/components/branch_assignment_card.dart` | 1 | `forms/` | Candidate |  | Reused by inventory add/edit stock item pages |
