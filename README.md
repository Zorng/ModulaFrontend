# Modular POS (Frontend)

Flutter frontend for the Modular POS system (web-first, mobile later).

## Start here
- Handover index: `handbook/handover/README.md`
- Agent guidance: `handbook/agents/agent_guide.md`
- Architecture: `handbook/architecture/overview.md`
- Non-negotiables: `handbook/non_negotiables.md`
- Testing + quality gate: `handbook/quality/testing.md`
- Responsive breakpoints: `docs/responsive_breakpoints.md`

## Quick start (dev)
1) Create `.env` from `.env.example`
2) Install deps: `flutter pub get`
3) Run (web): `flutter run -d chrome`

## CI
GitHub Actions runs on PRs:
- `flutter analyze`
- `flutter test`

Workflow: `.github/workflows/ci.yml`
