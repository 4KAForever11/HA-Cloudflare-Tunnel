#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADDON_DIR="${ROOT_DIR}/cloudflare_tunnel"
RUN_SCRIPT="${ADDON_DIR}/run.sh"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  rg -q --fixed-strings -- "$pattern" "$file" || fail "${file} does not contain: ${pattern}"
}

assert_file "${ROOT_DIR}/repository.yaml"
assert_file "${ADDON_DIR}/config.yaml"
assert_file "${ADDON_DIR}/build.yaml"
assert_file "${ADDON_DIR}/Dockerfile"
assert_file "$RUN_SCRIPT"
assert_file "${ROOT_DIR}/README.md"
assert_file "${ADDON_DIR}/DOCS.md"
assert_file "${ROOT_DIR}/.github/workflows/builder.yaml"

for arch in amd64 aarch64; do
  assert_contains "${ADDON_DIR}/config.yaml" "  - ${arch}"
done
assert_contains "${ADDON_DIR}/config.yaml" "tunnel_token: password"
assert_contains "${ADDON_DIR}/Dockerfile" "CLOUDFLARED_VERSION"
assert_contains "${ADDON_DIR}/Dockerfile" "sha256sum -c"
assert_contains "$RUN_SCRIPT" "TUNNEL_TOKEN"
assert_contains "$RUN_SCRIPT" "--no-autoupdate"
assert_contains "$RUN_SCRIPT" "exec cloudflared"

cat >"${TEMP_DIR}/bashio.sh" <<'STUB'
bashio::config() {
  case "$1" in
    tunnel_token) printf '%s' "${TEST_TOKEN:-}" ;;
    log_level) printf '%s' "${TEST_LOG_LEVEL:-info}" ;;
    protocol) printf '%s' "${TEST_PROTOCOL:-auto}" ;;
  esac
}
bashio::log.error() { printf '%s\n' "$*" >&2; }
STUB

cat >"${TEMP_DIR}/cloudflared" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "${TUNNEL_TOKEN:-}" >"${CAPTURE_DIR}/token"
printf '%s\n' "$@" >"${CAPTURE_DIR}/argv"
exit "${TEST_EXIT_CODE:-0}"
STUB
chmod +x "${TEMP_DIR}/cloudflared"

if BASH_ENV="${TEMP_DIR}/bashio.sh" PATH="${TEMP_DIR}:${PATH}" \
  TEST_TOKEN='   ' CAPTURE_DIR="${TEMP_DIR}" bash "$RUN_SCRIPT" \
  >"${TEMP_DIR}/missing.out" 2>&1; then
  fail "entrypoint accepted an empty token"
fi
rg -q 'Tunnel token is required' "${TEMP_DIR}/missing.out" || fail "missing-token error was not actionable"

TEST_SECRET='test-token-that-must-not-enter-argv'
if ! BASH_ENV="${TEMP_DIR}/bashio.sh" PATH="${TEMP_DIR}:${PATH}" \
  TEST_TOKEN="$TEST_SECRET" TEST_LOG_LEVEL=debug TEST_PROTOCOL=quic \
  CAPTURE_DIR="${TEMP_DIR}" bash "$RUN_SCRIPT" >"${TEMP_DIR}/run.out" 2>&1; then
  fail "entrypoint failed with valid configuration"
fi
[[ "$(<"${TEMP_DIR}/token")" == "$TEST_SECRET" ]] || fail "token was not exported to cloudflared"
if rg -q --fixed-strings "$TEST_SECRET" "${TEMP_DIR}/argv" "${TEMP_DIR}/run.out"; then
  fail "tunnel token appeared in cloudflared argv"
fi
rg -q --fixed-strings -- '--protocol' "${TEMP_DIR}/argv" || fail "protocol flag missing"
rg -q --fixed-strings -- 'quic' "${TEMP_DIR}/argv" || fail "protocol value missing"
rg -q --fixed-strings -- '--loglevel' "${TEMP_DIR}/argv" || fail "log level flag missing"

expected=$'tunnel\n--no-autoupdate\n--loglevel\ndebug\n--protocol\nquic\n--metrics\n127.0.0.1:2000\nrun'
[[ "$(<"${TEMP_DIR}/argv")" == "$expected" ]] || fail "unexpected cloudflared arguments"
for option in TEST_LOG_LEVEL TEST_PROTOCOL; do
  if env BASH_ENV="${TEMP_DIR}/bashio.sh" PATH="${TEMP_DIR}:${PATH}" \
    TEST_TOKEN="$TEST_SECRET" CAPTURE_DIR="${TEMP_DIR}" "$option=invalid" \
    bash "$RUN_SCRIPT" >"${TEMP_DIR}/invalid.out" 2>&1; then
    fail "accepted invalid $option"
  fi
  rg -q 'Unsupported' "${TEMP_DIR}/invalid.out" || fail "wrong validation failure"
done
status=0
BASH_ENV="${TEMP_DIR}/bashio.sh" PATH="${TEMP_DIR}:${PATH}" \
  TEST_TOKEN="$TEST_SECRET" CAPTURE_DIR="${TEMP_DIR}" TEST_EXIT_CODE=42 \
  bash "$RUN_SCRIPT" || status=$?
[[ "$status" == 42 ]] || fail "cloudflared exit status was swallowed"

printf 'PASS: add-on structure, token handling, and option mapping checks passed\n'
