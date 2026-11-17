# Home Assistant Cloudflare Tunnel Add-on Design

## Goal

Provide a Home Assistant OS add-on that runs an existing remotely-managed Cloudflare Tunnel inside Home Assistant. The add-on accepts a Tunnel Token, keeps `cloudflared` connected, and leaves hostname, DNS, ingress, and Access policy management in the Cloudflare dashboard.

## Scope

### Included

- A single Home Assistant OS add-on named Cloudflare Tunnel.
- Configuration of a required `tunnel_token`.
- Optional log level and transport protocol settings.
- A container entrypoint that starts `cloudflared tunnel run` and forwards logs to the add-on log stream.
- Multi-architecture metadata for supported Home Assistant OS targets: `amd64` and `aarch64`.
- GitHub Actions configuration for Home Assistant add-on builder releases to GHCR.
- Chinese and English documentation covering installation, token setup, hostname routing, and troubleshooting.

### Excluded

- Creating or deleting Cloudflare tunnels.
- Creating or changing DNS records.
- Managing Cloudflare Access applications or policies.
- Accepting Cloudflare API tokens.
- Publishing a web dashboard or exposing an add-on port.
- Supporting locally-managed tunnels that require credential JSON and ingress YAML.

## Architecture

The repository is a Home Assistant add-on repository with one add-on directory:

```text
.
├── repository.yaml
├── README.md
├── .github/workflows/builder.yaml
├── cloudflare_tunnel/
│   ├── config.yaml
│   ├── Dockerfile
│   ├── run.sh
│   ├── DOCS.md
│   └── translations/en.yaml
└── tests/
    └── test_addon.sh
```

The Docker image is built from Home Assistant's architecture-aware base image. The image installs the pinned `cloudflared` package from the official Cloudflare release archive selected by `BUILD_ARCH`, copies the entrypoint, and starts without requiring network access during container startup.

At runtime, Supervisor writes user configuration to `/data/options.json`. `run.sh` reads it directly with jq, validates the token, maps supported options to explicit `cloudflared` flags, and exports `TUNNEL_TOKEN` so the secret does not appear in the process argument list. The process is started with `cloudflared tunnel --no-autoupdate ... run`; enable the Supervisor Watchdog toggle in the add-on UI to recover unexpected process exits.

No host ports, host network, Docker socket, Supervisor API, or privileged capabilities are needed. `cloudflared` establishes outbound tunnel connections and forwards traffic according to the remotely-managed tunnel configuration.

## Configuration Contract

`cloudflare_tunnel/config.yaml` defines:

- `tunnel_token`: required secret string.
- `log_level`: enum `debug|info|warn|error|fatal`, default `info`.
- `protocol`: enum `auto|quic|http2`, default `auto`.

The add-on configuration is intentionally small. The token is stored by Supervisor as an add-on secret option and is never echoed by the entrypoint.

## Runtime Flow

1. Supervisor starts the add-on after Home Assistant services are available.
2. `run.sh` reads `/data/options.json` using jq without calling the Supervisor API.
3. The script rejects an empty token and exits non-zero with an actionable message.
4. The script exports `TUNNEL_TOKEN` and starts `cloudflared` with explicit runtime flags.
5. Cloudflare connects the replica to the already-configured tunnel and applies its remote hostname-to-service routes.
6. Enable the Supervisor Watchdog toggle to recover unexpected process exits.

## Failure Handling

- Missing or blank token: fail fast and print a remediation message without printing the value.
- Invalid enum option: fail fast through schema validation before the container starts.
- Cloudflare connection loss: let `cloudflared` retry using its native backoff and preserve the process.
- Process exit: enable Supervisor Watchdog; there is no `restart` field in the add-on configuration schema.
- Origin routing errors: document that hostname and service URL are configured in Cloudflare, not in this add-on.

## Security

- Tunnel Token is passed through the `TUNNEL_TOKEN` environment variable and not as a command-line argument.
- No Cloudflare API credentials are accepted or required.
- The add-on has no published ports and uses no privileged Docker settings.
- The Dockerfile pins the Cloudflare release version through an explicit build argument and verifies the downloaded archive checksum.
- Documentation warns users to rotate a token if it has been exposed in logs, screenshots, or shell history.

## Release and GitHub Publishing

The repository contains a GitHub Actions workflow using the current composable Home Assistant builder actions. On published GitHub releases, the workflow builds `amd64` and `aarch64` images and publishes a multi-architecture image to GHCR. The repository URL is `https://github.com/4KAForever11/HA-Cloudflare-Tunnel` and the optional release image is `ghcr.io/4kaforever11/ha-cloudflare-tunnel`. Default installation builds locally from source (no `image` field) so a first-time private GHCR package cannot block installation. Main pushes only build and test; published Releases push versioned images.

The 32-bit architectures `armv7`, `armhf`, and `i386` are excluded because Home Assistant OS 17 removed 32-bit targets and current Home Assistant builder actions support only `amd64` and `aarch64`.

## Testing

The test suite is shell-based and does not require Home Assistant or Docker:

- Validate YAML syntax and required keys.
- Verify the Dockerfile contains the required build arguments and checksum verification.
- Execute `run.sh` in real JSON options and a stubbed cloudflared boundary to confirm missing-token failure and flag construction without launching a real tunnel.
- Run `shellcheck` when available.

Local verification runs Bash entrypoint behavior checks, Python YAML and metadata checks, ShellCheck and actionlint. GitHub Actions builds both images and runs the real binary with `--version`. A live tunnel and HAOS installation still require the deployment environment and user token.

## Open Decisions Resolved

- Use an Add-on rather than a custom Home Assistant integration because the requested behavior is a long-running system daemon, not an entity or config-flow service.
- Keep all Cloudflare resource configuration in the dashboard because the selected token-only mode intentionally avoids account API permissions.
- Use the official `cloudflare/cloudflared` release artifact rather than a third-party package so the runtime binary is controlled and reproducible.
