#!/usr/bin/with-contenv bashio
set -euo pipefail

token="$(bashio::config 'tunnel_token')"
if [[ -z "${token//[[:space:]]/}" ]]; then
  bashio::log.error "Tunnel token is required. Add it in the add-on Configuration tab."
  exit 1
fi

log_level="$(bashio::config 'log_level')"
protocol="$(bashio::config 'protocol')"

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
