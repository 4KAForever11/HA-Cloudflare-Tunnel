# Cloudflare Tunnel Add-on Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a GitHub-ready Home Assistant OS add-on that runs an existing Cloudflare Tunnel using a Tunnel Token.

**Architecture:** A single add-on directory contains Home Assistant metadata, a multi-architecture Docker build, and a Bash entrypoint. The add-on reads Supervisor-provided options, exports the token as `TUNNEL_TOKEN`, and runs `cloudflared tunnel run` without host ports or privileged access. Repository-level documentation and a GitHub Actions workflow cover installation and GHCR publishing.

**Tech Stack:** Home Assistant Add-on format, Docker, Bash, Bashio, Cloudflare `cloudflared`, GitHub Actions, YAML, shell tests.

**Spec:** `docs/superpowers/specs/2026-11-18-cloudflare-tunnel-addon-design.md`

## Global Constraints

- The add-on connects an existing remotely-managed Tunnel and never creates Cloudflare resources.
- `tunnel_token` is required and must never be printed by the entrypoint.
- No host ports, host networking, Docker socket, Supervisor API, or privileged capabilities.
- Support Home Assistant's current `amd64` and `aarch64` architectures.
- README and add-on documentation must provide both Chinese and English instructions.
- Cloudflare binary version and SHA-256 checksums must be explicit build inputs.

---

### Task 1: Repository metadata and add-on skeleton

**Files:**
- Create: `repository.yaml`
- Create: `cloudflare_tunnel/config.yaml`
- Create: `cloudflare_tunnel/build.yaml`
- Create: `cloudflare_tunnel/translations/en.yaml`

**Interfaces:**
- Produces the Home Assistant repository and add-on metadata consumed by Supervisor and the builder.

- [ ] Create repository metadata with a stable name, URL placeholder-free local metadata, and a single add-on path.
- [ ] Define add-on name, slug, version, startup mode, supported architectures, secret token schema, and enum options.
- [ ] Define architecture build arguments and explicit Cloudflare release version/checksum inputs.
- [ ] Add English configuration labels and descriptions for Supervisor.
- [ ] Validate YAML syntax and required keys with a shell test.

### Task 2: Runtime image and entrypoint

**Files:**
- Create: `cloudflare_tunnel/Dockerfile`
- Create: `cloudflare_tunnel/run.sh`

**Interfaces:**
- Consumes `/data/options.json` through Bashio.
- Produces a long-running `cloudflared` process with `TUNNEL_TOKEN` in the environment and no token in argv.

- [ ] Write the failing shell assertions for missing-token failure, secret-free command construction, and supported option mapping in `tests/test_addon.sh`.
- [ ] Run the test to confirm it fails because `run.sh` and the metadata do not exist.
- [ ] Implement the architecture-aware Dockerfile with pinned download URL and checksum verification.
- [ ] Implement `run.sh` with strict mode, token validation, safe option mapping, and `exec cloudflared ... run`.
- [ ] Run the shell tests and inspect the generated argv in a stubbed environment.
- [ ] Run ShellCheck when installed and fix actionable findings.

### Task 3: User documentation in Chinese and English

**Files:**
- Create: `README.md`
- Create: `cloudflare_tunnel/DOCS.md`

**Interfaces:**
- Documents installation, token retrieval, hostname routing, origin service examples, security, upgrades, and troubleshooting in both languages.

- [ ] Document adding the GitHub repository to HAOS and installing the add-on.
- [ ] Document creating or selecting a remotely-managed Cloudflare Tunnel and copying its token.
- [ ] Document configuring public hostnames and service URLs in Cloudflare Zero Trust.
- [ ] Document Home Assistant reverse-proxy settings and common connection failures.
- [ ] Document GitHub Actions and GHCR publishing expectations without requiring users to edit generated image names.
- [ ] Check that every required configuration key appears in both language sections.

### Task 4: GitHub Actions publishing and repository hygiene

**Files:**
- Create: `.github/workflows/builder.yaml`
- Create: `.gitignore`
- Create: `LICENSE`

**Interfaces:**
- Builds and publishes architecture-specific add-on images to GHCR on tagged or main-branch releases.

- [ ] Configure current Home Assistant composable builder actions with repository owner/name derived from GitHub context.
- [ ] Grant only package write and repository read permissions.
- [ ] Add workflow paths and release triggers that avoid publishing on unrelated documentation-only edits.
- [ ] Add ignore rules for local test artifacts and secrets.
- [ ] Add an MIT license with a generic copyright holder line suitable for the repository owner to update.
- [ ] Validate workflow YAML and ensure image references are consistent with the add-on metadata.

### Task 5: Full verification and GitHub preparation

**Files:**
- Modify: `tests/test_addon.sh`

**Interfaces:**
- Provides a repeatable local verification command for the repository.

- [ ] Run the complete shell test suite from a clean PowerShell invocation.
- [ ] Run YAML parsing checks with an available parser or a Python fallback.
- [ ] Run Dockerfile static checks and a build when Docker is available; report unavailable tools explicitly.
- [ ] Initialize git if needed, inspect status, and verify no secret or token value is present.
- [ ] Add a concise `git` publishing section to the README with exact commands and a note that the remote URL is repository-specific.
- [ ] Report the remaining user action: create or provide the GitHub remote URL and push credentials if the user wants an actual push.
