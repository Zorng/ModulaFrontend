# Modular POS (Frontend)

Flutter frontenddd for the Modular POS system (web-first, mobile later).

## Start here
- Handover index: `handbook/handover/README.md`
- Runtime config guide: `handbook/handover/dart_define_run_guide.md`
- Agent guidance: `handbook/agents/agent_guide.md`
- Architecture: `handbook/architecture/overview.md`
- Non-negotiables: `handbook/non_negotiables.md`
- Testing + quality gate: `handbook/quality/testing.md`
- Responsive breakpoints: `docs/responsive_breakpoints.md`

## Quick start (dev)
1) Install deps: `flutter pub get`
2) Run (web) with defines:
   - `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000`
   - or easier:
     - `cp .env.web.local.example .env.web.local`
     - `bash scripts/run-web-local.sh`
3) Optional local fallback: create `.env` from `.env.example` for non-web/dev convenience
4) See full keys/examples: `handbook/handover/dart_define_run_guide.md`

## CI
GitHub Actions runs on PRs:
- `flutter analyze`
- `flutter test`

Workflow: `.github/workflows/ci.yml`
