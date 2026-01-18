# Widget Reuse Candidates (Refactor Tracking)

This file tracks widgets that are potentially reusable across multiple features.
It is a refactor-time working document (not long-lived handbook documentation).

Goal:
- Reduce widget bloat and duplication
- Make common UI primitives discoverable
- Avoid premature “core” abstractions while features are still evolving

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

## Candidate list

| Widget | Current Path | Used In Features | Candidate Category | Status | Promoted To | Notes / Jira |
|---|---|---:|---|---|---|---|
| `SaleCartBottomBar` | `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_bottom_bar.dart` | 1 | `layout/` | Candidate |  | Sale cart: “total + CTA” bottom bar |
| `SaleCartReadOnlyBanner` | `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_readonly_banner.dart` | 1 | `feedback/` | Candidate |  | Sale cart: read-only banner + action |
| `SaleOrderTypeSelector` | `lib/features/sale/ui/view/sale_cart/widgets/sale_order_type_selector.dart` | 1 | `forms/` | Candidate |  | Sale cart: order type selector chips |
| `SaleCartContent` | `lib/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart` | 1 | `display/` | Candidate |  | Sale cart: cart lines + payments UI (likely stays feature-local) |
| `SaleItemDetailBottomBar` | `lib/features/sale/ui/view/sale_item_detail/widgets/sale_item_detail_bottom_bar.dart` | 1 | `layout/` | Candidate |  | Sale item detail: “total + qty + Add Item” bottom bar |
| `QuantityStepper` | `lib/features/sale/ui/components/quantity_stepper.dart` | 1 | `forms/` | Candidate |  | Used in sale cart lines + sale item detail |
| `SaleItemDetailImage` | `lib/features/sale/ui/view/sale_item_detail/widgets/sale_item_detail_image.dart` | 1 | `media/` | Candidate |  | Sale item detail: image + placeholder |
| `SaleItemModifierGroupSection` | `lib/features/sale/ui/view/sale_item_detail/widgets/sale_item_modifier_group_section.dart` | 1 | `forms/` | Candidate |  | Sale item detail: modifier selection section |
| `FormTextField` | `lib/features/staff/ui/widgets/form_text_field.dart` | 1 | `forms/` | Candidate |  | If reused outside staff, promote to core |
| `FormDropdownField` | `lib/features/staff/ui/widgets/form_dropdown_field.dart` | 1 | `forms/` | Candidate |  | If reused outside staff, promote to core |
| `AppFilterDropdown` | `lib/features/staff/ui/widgets/app_filter_dropdown.dart` | 1 | `forms/` | Candidate |  | Might be reusable for inventory/report filters |
| `InventorySectionCard` | `lib/features/inventory/ui/widgets/inventory_section_card.dart` | 1 | `layout/` | Candidate |  | Compare with `lib/core/widgets/layout/app_section_card.dart` |
| `InventoryDropdown` | `lib/features/inventory/ui/widgets/inventory_dropdown.dart` | 1 | `forms/` | Candidate |  | Likely becomes shared dropdown pattern |
