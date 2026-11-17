# Home Assistant Cloudflare Tunnel

[简体中文](README.md) | **English**

Run a Cloudflare Tunnel connector as a Home Assistant OS add-on. This add-on connects to a tunnel you have already created in Cloudflare Zero Trust. It does not create tunnels, DNS records, hostnames, or Access policies.

## Requirements

- Home Assistant OS on `amd64` or `aarch64`.
- A remotely-managed Cloudflare Tunnel and its Tunnel Token.
- A public hostname and origin service configured in Cloudflare Zero Trust.

## Install

1. In Home Assistant, open **Settings > Add-ons > Add-on Store > ⋮ > Repositories**.
2. Add this repository: `https://github.com/4KAForever11/HA-Cloudflare-Tunnel`.
3. Install **Cloudflare Tunnel** from the store.
4. Open the add-on **Configuration** tab, paste the Tunnel Token into **Tunnel token**, and save.
5. Start the add-on and confirm the tunnel connection. Visit the hostname once; if it returns 400, obtain the proxy source address from the corresponding HA log.
6. Configure reverse-proxy trust below, complete the restart and confirmation, and visit the hostname again to verify the login page.


## Cloudflare setup

In Cloudflare Zero Trust, create or select a remotely-managed tunnel, copy its token, and add a **Public Hostname**. For Home Assistant, use an origin service such as `http://<HOME_ASSISTANT_LAN_IP>:8123`. Cloudflare manages the DNS record and sends hostname traffic to that service through the tunnel.

**For HTTP 400, check reverse-proxy trust first.** On **Home Assistant 2026.8+**, use **Settings → System → Network → HTTP server → Reverse proxy**. Enable **Trust X-Forwarded-For** and add the actual proxy address. Save, reconnect, and confirm within **5 minutes** to avoid rollback. YAML HTTP changes are ignored after migration. See [setup and troubleshooting](cloudflare_tunnel/DOCS.md) for details and legacy YAML instructions.

Use the origin's actual protocol and port. Private HTTP and public HTTPS can coexist; a 400 alone is not a reason to switch a working HTTP origin to HTTPS.

## Options

| Option | Values | Default | Description |
| --- | --- | --- | --- |
| Tunnel token | Secret string | Required | Token for the existing remotely-managed tunnel. |
| Log level | `debug`, `info`, `warn`, `error`, `fatal` | `info` | `cloudflared` log verbosity. |
| Protocol | `auto`, `quic`, `http2` | `auto` | Tunnel transport selection. |

## Build, verify and publish

HAOS builds this add-on from source by default, so installation does not depend on a public GHCR package. The first installation downloads a base image and the cloudflared binary. HAOS needs access to GHCR, GitHub, and Alpine package mirrors.

Local checks (Bash, Python, PyYAML, jq and ripgrep required):

```bash
python -m pip install PyYAML==6.0.3
bash tests/test_addon.sh
python tests/validate_repository.py
```

GitHub Actions checks and builds both architectures on build-related main pushes and manual dispatches. Only published GitHub Releases push and sign versioned GHCR images. The tag must match the add-on version (currently `1.0.0`; `v1.0.0` is also accepted). Bump the version for each release; existing version tags are not overwritten.

Optional prebuilt installation: after a successful Release build, make the `ha-cloudflare-tunnel` GHCR package Public and add this to `cloudflare_tunnel/config.yaml`:

```yaml
image: ghcr.io/4kaforever11/ha-cloudflare-tunnel
```

The default source installation needs no package setup. Forks must update the repository URLs and GHCR namespace. Binary versions, SHA-256 values and base-image digests live in `cloudflare_tunnel/build.yaml`; rerun checks and image builds after upgrading.

## License

MIT. See [LICENSE](LICENSE).
