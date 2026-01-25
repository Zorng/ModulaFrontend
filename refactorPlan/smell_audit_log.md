# Smell Audit Log

Track identified smells, severity, and suggested fixes.

| ID | File | Smell | Category | Severity | Recommendation | Status |
|----|------|-------|----------|----------|----------------|--------|
| SA-001 | lib/app.dart | Large file (563 LOC) | Architecture & navigation | P1 | Split routes into feature route files and compose in app.dart | Done |
| SA-002 | lib/features/menu/data/menu_repository.dart | Large file (586 LOC) | Data layer | P1 | Split mapping helpers + repository into smaller units | Done |
| SA-003 | lib/features/inventory/ui/view/stock_item_detail/stock_item_detail_page.dart | Large file (490 LOC) | Widget bloat | P1 | Extract sections into widgets (summary, meta, actions) | Done |
| SA-004 | lib/features/inventory/ui/view/add_stock_item/add_stock_item_page.dart | Large file (474 LOC) | Widget bloat | P1 | Extract form sections + helper widgets | Done |
| SA-005 | lib/features/menu/data/menu_api.dart | Large file (458 LOC) | Data layer | P1 | Split request helpers / parsing | Done |
| SA-006 | lib/features/sale/ui/viewmodels/sale_cart_viewmodel.dart | Large file (451 LOC) | State management | P1 | Split into smaller methods / helpers | Done |
| SA-007 | lib/features/sale/ui/view/sale_cart/widgets/sale_cart_content.dart | Large file (425 LOC) | Widget bloat | P1 | Extract sections into widgets | Done |
| SA-008 | lib/features/sale/ui/view/order/widgets/order_status_bottom_sheet.dart | Navigator usage | Routing | P2 | Use go_router pop or modal helpers | Done |
| SA-009 | lib/features/sale/ui/view/view_carts/view_carts_page.dart | Navigator usage | Routing | P2 | Use context.pop/context.go as appropriate | Done |
| SA-010 | lib/features/inventory/ui/view/category_management/category_management_page.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-011 | lib/features/inventory/ui/view/category_management/widgets/inventory_category_tile.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-012 | lib/features/inventory/ui/view/restock_stock_item/restock_stock_item_page.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-013 | lib/features/inventory/ui/view/add_stock_item/add_stock_item_page.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-014 | lib/features/inventory/ui/view/stock_adjust_quantity/stock_adjust_quantity_page.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-015 | lib/features/menu/ui/view/edit_modifier_group/edit_modifier_group_page.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-016 | lib/features/menu/ui/view/edit_category/edit_category_page.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-017 | lib/features/menu/ui/view/add_modifier_group/add_modifier_group_page.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-018 | lib/features/menu/ui/view/menu_item_form/menu_item_form_utils.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-019 | lib/features/menu/ui/view/categories_management/widgets/edit_category_sheet.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-020 | lib/features/cash_session/ui/widgets/add_cash_movement_modal.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-021 | lib/features/cash_session/ui/widgets/close_session_modal.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-022 | lib/features/cash_session/ui/widgets/start_session_modal.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-023 | lib/features/policy/ui/view/vat_policy_detail/widgets/vat_rate_bottom_sheet.dart | Navigator usage | Routing | P2 | Replace Navigator.pop with context.pop | Done |
| SA-024 | lib/features/inventory/data/stock_item_api.dart | Mock data embedded in API/repo | Data layer | P1 | Move mock data to fixtures/dev seed layer | Done (mock data removed) |
