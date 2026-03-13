#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${PWD}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.4}"
CACHE_ROOT="${NETLIFY_CACHE_DIR:-$HOME/.cache}"
FLUTTER_DIR="${CACHE_ROOT}/flutter-sdk"

if [ ! -d "${FLUTTER_DIR}/.git" ]; then
  git clone "https://github.com/flutter/flutter.git" \
    --depth 1 \
    --branch "${FLUTTER_CHANNEL}" \
    "${FLUTTER_DIR}"
fi

git -C "${FLUTTER_DIR}" fetch --depth 1 origin "${FLUTTER_VERSION}"
git -C "${FLUTTER_DIR}" checkout "${FLUTTER_VERSION}"

export PATH="${FLUTTER_DIR}/bin:${PATH}"

cd "${REPO_ROOT}"

flutter config --enable-web
flutter pub get

flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL:-}" \
  --dart-define=AUTH_API_PREFIX="${AUTH_API_PREFIX:-}" \
  --dart-define=MENU_API_PREFIX="${MENU_API_PREFIX:-}" \
  --dart-define=INVENTORY_API_PREFIX="${INVENTORY_API_PREFIX:-}" \
  --dart-define=SALES_API_PREFIX="${SALES_API_PREFIX:-}" \
  --dart-define=CASH_API_PREFIX="${CASH_API_PREFIX:-}" \
  --dart-define=REPORTING_API_PREFIX="${REPORTING_API_PREFIX:-}" \
  --dart-define=POLICY_API_PREFIX="${POLICY_API_PREFIX:-}" \
  --dart-define=ATTENDANCE_API_PREFIX="${ATTENDANCE_API_PREFIX:-}" \
  --dart-define=BRANCH_API_PREFIX="${BRANCH_API_PREFIX:-}" \
  --dart-define=AUTH_REPOSITORY_MODE="${AUTH_REPOSITORY_MODE:-api}" \
  --dart-define=TENANT_REPOSITORY_MODE="${TENANT_REPOSITORY_MODE:-api}" \
  --dart-define=BRANCH_REPOSITORY_MODE="${BRANCH_REPOSITORY_MODE:-api}" \
  --dart-define=INVENTORY_REPOSITORY_MODE="${INVENTORY_REPOSITORY_MODE:-api}" \
  --dart-define=POLICY_REPOSITORY_MODE="${POLICY_REPOSITORY_MODE:-api}" \
  --dart-define=CASH_SESSION_REPOSITORY_MODE="${CASH_SESSION_REPOSITORY_MODE:-api}" \
  --dart-define=ATTENDANCE_REPOSITORY_MODE="${ATTENDANCE_REPOSITORY_MODE:-api}" \
  --dart-define=SHOW_DEBUG_ERRORS="${SHOW_DEBUG_ERRORS:-false}"
