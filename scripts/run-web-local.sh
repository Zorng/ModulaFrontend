#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${PWD}"
ENV_FILE="${REPO_ROOT}/.env.web.local"
FLUTTER_DEVICE="${FLUTTER_DEVICE:-chrome}"

if [ -f "${ENV_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

flutter run -d "${FLUTTER_DEVICE}" \
  --dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:3000}" \
  --dart-define=AUTH_API_PREFIX="${AUTH_API_PREFIX:-/v0/auth}" \
  --dart-define=MENU_API_PREFIX="${MENU_API_PREFIX:-/v0/menu}" \
  --dart-define=INVENTORY_API_PREFIX="${INVENTORY_API_PREFIX:-/v0/inventory}" \
  --dart-define=SALES_API_PREFIX="${SALES_API_PREFIX:-/v0/sales}" \
  --dart-define=CASH_API_PREFIX="${CASH_API_PREFIX:-/v0/cash}" \
  --dart-define=REPORTING_API_PREFIX="${REPORTING_API_PREFIX:-/v0/reports}" \
  --dart-define=POLICY_API_PREFIX="${POLICY_API_PREFIX:-/v0/policy}" \
  --dart-define=ATTENDANCE_API_PREFIX="${ATTENDANCE_API_PREFIX:-/v0/attendance}" \
  --dart-define=BRANCH_API_PREFIX="${BRANCH_API_PREFIX:-/v0/branches}" \
  --dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY:-}" \
  --dart-define=AUTH_REPOSITORY_MODE="${AUTH_REPOSITORY_MODE:-api}" \
  --dart-define=TENANT_REPOSITORY_MODE="${TENANT_REPOSITORY_MODE:-api}" \
  --dart-define=BRANCH_REPOSITORY_MODE="${BRANCH_REPOSITORY_MODE:-api}" \
  --dart-define=INVENTORY_REPOSITORY_MODE="${INVENTORY_REPOSITORY_MODE:-api}" \
  --dart-define=POLICY_REPOSITORY_MODE="${POLICY_REPOSITORY_MODE:-api}" \
  --dart-define=CASH_SESSION_REPOSITORY_MODE="${CASH_SESSION_REPOSITORY_MODE:-api}" \
  --dart-define=ATTENDANCE_REPOSITORY_MODE="${ATTENDANCE_REPOSITORY_MODE:-api}" \
  --dart-define=SHOW_DEBUG_ERRORS="${SHOW_DEBUG_ERRORS:-true}" \
  "$@"
