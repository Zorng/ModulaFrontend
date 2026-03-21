#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${PWD}"
METADATA_FILE="${REPO_ROOT}/.metadata"
CACHE_ROOT="${NETLIFY_CACHE_DIR:-$HOME/.cache}"
FLUTTER_DIR="${CACHE_ROOT}/flutter-sdk"

read_metadata_value() {
  local key="$1"
  if [ ! -f "${METADATA_FILE}" ]; then
    return 0
  fi
  awk -F'"' -v key="${key}" '$1 ~ "^[[:space:]]*" key ": " { print $2; exit }' "${METADATA_FILE}"
}

DEFAULT_FLUTTER_CHANNEL="$(read_metadata_value channel)"
DEFAULT_FLUTTER_REF="$(read_metadata_value revision)"

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-${DEFAULT_FLUTTER_CHANNEL:-stable}}"
FLUTTER_VERSION="${FLUTTER_VERSION:-${DEFAULT_FLUTTER_REF:-}}"

if [ ! -d "${FLUTTER_DIR}/.git" ]; then
  git clone "https://github.com/flutter/flutter.git" \
    --depth 1 \
    --branch "${FLUTTER_CHANNEL}" \
    "${FLUTTER_DIR}"
fi

if [ -n "${FLUTTER_VERSION}" ]; then
  git -C "${FLUTTER_DIR}" fetch --depth 1 origin "${FLUTTER_VERSION}"
  git -C "${FLUTTER_DIR}" checkout --detach FETCH_HEAD
else
  git -C "${FLUTTER_DIR}" fetch --depth 1 origin "${FLUTTER_CHANNEL}"
  git -C "${FLUTTER_DIR}" checkout "${FLUTTER_CHANNEL}"
  git -C "${FLUTTER_DIR}" reset --hard "origin/${FLUTTER_CHANNEL}"
fi

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
