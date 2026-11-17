#!/usr/bin/with-contenv bashio
set -euo pipefail

options_file="${ADDON_OPTIONS_FILE:-/data/options.json}"
if ! jq -e 'type == "object" and (.tunnel_token | type == "string") and
  (.log_level | type == "string") and (.protocol | type == "string")' \
  "${options_file}" >/dev/null 2>&1; then
  bashio::log.error "Invalid add-on options. Configure a tunnel token, log level and protocol."
  exit 1
fi

token="$(jq -rj '.tunnel_token' "${options_file}")"
if [[ -z "${token//[[:space:]]/}" ]]; then
  bashio::log.error "Tunnel token is required. Add it in the add-on Configuration tab."
  exit 1
fi

log_level="$(jq -rj '.log_level' "${options_file}")"
protocol="$(jq -rj '.protocol' "${options_file}")"

case "${log_level}" in
  debug|info|warn|error|fatal) ;;
  *) bashio::log.error "Unsupported log level configured."; exit 1 ;;
esac
case "${protocol}" in
  auto|quic|http2) ;;
  *) bashio::log.error "Unsupported transport protocol configured."; exit 1 ;;
esac

export TUNNEL_TOKEN="${token}"
unset token

exec cloudflared tunnel \
  --no-autoupdate \
  --loglevel "${log_level}" \
  --protocol "${protocol}" \
  --metrics 127.0.0.1:2000 \
  run
