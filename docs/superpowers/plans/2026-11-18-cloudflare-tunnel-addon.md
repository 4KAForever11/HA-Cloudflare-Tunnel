# Cloudflare Tunnel Add-on Implementation Plan

**Goal:** Deliver a token-based Home Assistant OS add-on and publish its repository with separate Chinese and English READMEs.

**Spec:** `docs/superpowers/specs/2026-11-18-cloudflare-tunnel-addon-design.md`

## Completed implementation

- [x] Add repository metadata, secret configuration schema, Chinese/English labels and amd64/aarch64 build inputs.
- [x] Pin the cloudflared release, SHA-256 checksums and Home Assistant base-image digests.
- [x] Run cloudflared with an environment token, explicit validated options and loopback-only metrics.
- [x] Test empty-token rejection, invalid options, exact argv, token handling and child exit status.
- [x] Provide README.md in Chinese, README.en.md in English and bilingual DOCS.md including reverse-proxy configuration.
- [x] Add CI checks and both architecture builds; publish versioned signed GHCR images only on a GitHub Release.
- [x] Run Bash tests, Python metadata checks, ShellCheck and actionlint locally.
- [x] Independently review the runtime, pinned builder action and documentation.
- [x] Upload to the public `4KAForever11/HA-Cloudflare-Tunnel` GitHub repository.
- [x] Observe successful GitHub amd64/aarch64 builds and real `cloudflared --version` smoke tests.

## Resolved implementation choices

- Current Home Assistant builds target amd64 and aarch64. Legacy 32-bit targets are excluded.
- Default installation builds on HAOS from source; it does not depend on an already-published public GHCR package.
- Binary auto-update stays disabled; Supervisor manages add-on updates.
- Enable Supervisor Watchdog in the UI for recovery. The metadata does not use the nonexistent `restart` option.
- This Windows host has Git Bash but no Docker daemon. Actual container builds ran on GitHub's native amd64 and ARM64 runners.

## Deployment verification still needed

The target HAOS device and a real Tunnel Token were not provided. Install the add-on, configure the public hostname and trusted proxy, and verify HTTPS access through the user's domain. The repository's automated checks do not establish live tunnel connectivity.
