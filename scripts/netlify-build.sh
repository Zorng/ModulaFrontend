#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${PWD}"
CACHE_ROOT="${NETLIFY_CACHE_DIR:-$HOME/.cache}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.38.9}"
FLUTTER_DIR="${CACHE_ROOT}/flutter-sdk-${FLUTTER_VERSION}-${FLUTTER_CHANNEL}"
FLUTTER_ARCHIVE="/tmp/flutter-${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"

if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  rm -rf "${FLUTTER_DIR}" "${CACHE_ROOT}/flutter"
  curl -fL "${FLUTTER_URL}" -o "${FLUTTER_ARCHIVE}"
  tar -xf "${FLUTTER_ARCHIVE}" -C "${CACHE_ROOT}"
  mv "${CACHE_ROOT}/flutter" "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter --version

cd "${REPO_ROOT}"

flutter config --enable-web
flutter pub get --enforce-lockfile

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
