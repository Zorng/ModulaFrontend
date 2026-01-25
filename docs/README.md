# `docs/` — Product Specs & Reference

This folder is for **product/spec artifacts** (what the system should do), not engineering process.

Engineering/workflow docs live in `handbook/`.

## Primary spec sources
- Module specifications: `docs/modSpec/`
- API contracts: `docs/apiContracts/`
- API schemas: `docs/apiSchema/`
- Breakpoints reference: `docs/responsive_breakpoints.md` (used by `handbook/non_negotiables.md`)

## Engineering docs (not here)
If you are documenting implementation conventions (providers, routing, widgets, testing, error handling), put it in:
- `handbook/`

## Cleanup status
We are cleaning up legacy top-level docs so `docs/` stays navigable.

Plan: `handbook/docs_cleanup.md`

### Top-level legacy docs (classification)
| File | Intent | Action |
|---|---|---|
| `docs/auth_module_overview.md` | wiring/network/env notes | moved to `handbook/architecture/auth.md` (stub kept) |
| `docs/common_widgets_guide.md` | shared widget guidance | moved to `handbook/architecture/widget_gallery.md` (stub kept) |
| `docs/testing_data_layer.md` | testing guidance | moved to `handbook/quality/data_layer_testing.md` (stub kept) |
| `docs/theme_usage.md` | theming guidance | moved to `handbook/architecture/theme.md` (stub kept) |
| `docs/sale_module.md` | legacy sale notes | archive if superseded by `docs/modSpec/sale_module.md` |
| `docs/cashier_cash_session.md` | legacy cash session notes | archive if superseded by `docs/modSpec/cashSession_module.md` |
| `docs/inventory_moudule_context.md` | legacy inventory notes | archive after review |
| `docs/inventory_context_extended.md` | inventory unit model notes | keep (until superseded by modspec) |
| `docs/policy_module_context.md` | policy context notes | archive after review |
| `docs/settings_module_context.md` | settings context notes | archive after review |
| `docs/modula_overview.md` | product/vision overview | keep |
| `docs/modula_capstone_1_scope.md` | product scope | keep |
| `docs/DEVICE_AGNOSTIC_SESSIONS.md` | product/backend behavior note | keep |
| `docs/test.md` | placeholder | delete or archive |

### Archive bucket
Legacy files will be moved into `docs/_archive/` and may be replaced by a stub that links to the canonical location.

## Canonical engineering docs
If you landed here looking for implementation conventions, go to `handbook/`:
- `handbook/architecture/overview.md`
- `handbook/architecture/providers.md`
- `handbook/architecture/navigation.md`
- `handbook/architecture/widgets.md`
- `handbook/quality/testing.md`
- `handbook/quality/error_handling.md`
