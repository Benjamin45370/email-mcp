# Email MCP Server

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![license](https://img.shields.io/github/license/codefuturist/email-mcp.svg?style=flat-square)](LICENSE)
[![npm version](https://img.shields.io/npm/v/@codefuturist/email-mcp.svg?style=flat-square)](https://www.npmjs.com/package/@codefuturist/email-mcp)
[![npm downloads](https://img.shields.io/npm/dm/@codefuturist/email-mcp.svg?style=flat-square)](https://www.npmjs.com/package/@codefuturist/email-mcp)
[![CI](https://img.shields.io/github/actions/workflow/status/codefuturist/email-mcp/ci.yml?branch=main&style=flat-square&label=CI)](https://github.com/codefuturist/email-mcp/actions/workflows/ci.yml)

An MCP (Model Context Protocol) server providing comprehensive email capabilities via IMAP and SMTP.

Enables AI assistants to read, search, send, manage, schedule, and analyze emails across multiple accounts. Exposes 52 tools, 7 prompts, and 6 resources over the MCP protocol with OAuth2 support _(experimental)_, email scheduling, calendar extraction, analytics, provider-aware label management, real-time IMAP IDLE watcher with AI-powered triage, instant verification-code catching with clipboard copy, customizable presets and static rules, and a guided setup wizard.

Built on the MCP TypeScript SDK v2 (spec revision 2026-07-28), it serves over **stdio** for local clients or **Streamable HTTP** for networked access — existing stdio configurations keep working unchanged.

## Highlights

| Feature | email-mcp | Typical MCP email |
|---------|:---------:|:-----------------:|
| Multi-account | ✅ | ❌ |
| Send / reply / forward | ✅ | ✅ |
| Drafts & templates | ✅ | ❌ |
| Labels & bulk ops | ✅ provider-aware | ❌ |
| Schedule future emails | ✅ | ❌ |
| Real-time IMAP IDLE watcher | ✅ | ❌ |
| Verification codes → clipboard | ✅ concealed + auto-clear | ❌ |
| AI triage with presets | ✅ | ❌ |
| Desktop & webhook alerts | ✅ | ❌ |
| Calendar (ICS) extraction | ✅ | ❌ |
| Email analytics | ✅ | ❌ |
| OAuth2 (Gmail / M365) | ✅ _experimental_ | ❌ |
| Guided setup wizard | ✅ auto-detect | ❌ |
| Streamable HTTP transport | ✅ | ❌ |

## Table of Contents

- [Highlights](#highlights)
- [Security](#security)
- [Background](#background)
- [Install](#install)
- [Usage](#usage)
- [API](#api)
- [Roadmap](#roadmap)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

## Security

- All connections use TLS/STARTTLS encryption
- Passwords are never logged; audit trail records operations without credentials
- Token-bucket rate limiter prevents abuse (one bucket per account, sharing a global `rate_limit`)
- OAuth2 XOAUTH2 authentication for Gmail and Microsoft 365 _(experimental)_
- Attachment downloads capped at 5 MB with base64 encoding

## Background

Most MCP email implementations provide only basic read/send. This server aims to be a full-featured email client for AI assistants, covering the entire lifecycle: reading, composing, managing, scheduling, and analyzing email — all from a single MCP server.

Key design decisions:

- **XDG-compliant config** — TOML at `~/.config/email-mcp/config.toml`
- **Multi-account** — Operate across multiple IMAP/SMTP accounts simultaneously
- **Layered services** — Business logic is decoupled from MCP wiring for testability
- **Provider auto-detection** — Gmail, Outlook, Yahoo, iCloud, Fastmail, ProtonMail, Zoho, GMX

## Install

Requires Node.js ≥ 24.

```bash
# Run directly (no install needed)
npx @codefuturist/email-mcp setup
# or
pnpm dlx @codefuturist/email-mcp setup

# Or install globally
npm install -g @codefuturist/email-mcp
# or
pnpm add -g @codefuturist/email-mcp
```

`npm install -g` fails with `EACCES` when npm's global prefix is a root-owned
directory (common on a system Node install) — the `npx`/`pnpm dlx` form above
avoids this entirely by not installing anything globally. If you do want a
permanent global install, fix npm's prefix instead of reaching for `sudo`
(`npm config set prefix ~/.npm-global` and add that to `PATH`, or use a Node
version manager like `nvm`/`fnm`/`volta`) — running `npm install -g` as root
routinely leaves root-owned files mixed into a user-owned `node_modules` tree,
which causes harder-to-diagnose permission errors on the *next* global install.

### Homebrew (native binary)

The prebuilt, dependency-free binary — no Node.js at runtime — from the
[codefuturist tap](https://github.com/codefuturist/homebrew-tap):

```bash
brew install codefuturist/tap/email-mcp
```

Published as a cask on every stable release; works on macOS (arm64 + x64) and
on Linuxbrew ≥ 4.3 (binary-only casks).

### Native binary (Bun)

A dependency-free single binary (minified + bytecode-precompiled, ~32 ms cold
start, no Node.js at runtime) can be compiled with [Bun](https://bun.sh):

```bash
bun run build:binary          # native binary → build/email-mcp
cp build/email-mcp ~/.local/bin/

bun run build:binaries        # release matrix: darwin-arm64/x64, linux-x64/arm64,
                              # windows-x64 → build/release/*.{tar.gz,zip} + sha256 checksums
```

Prebuilt binaries for every release are built by CI with GoReleaser Pro
(`.goreleaser.yaml`) for all common platforms — Linux glibc + musl, macOS, and
Windows, each x64 + arm64 where Bun supports it — provenance-attested (verify with
`gh attestation verify <asset> --repo codefuturist/email-mcp`) and shipped with
[GitHub releases](https://github.com/codefuturist/email-mcp/releases) —
installable via mise: `mise use -g ubi:codefuturist/email-mcp`.

The same binary can also be built locally from the published npm package (no
checkout needed; ≥ 0.5.1, which carries the imapflow TLS fix at runtime —
older versions need the repo's pnpm patch). Note that a plain `bun add -g`
shim executes `dist/main.js` under node via its shebang, so the compile step
is what buys the ~11 ms cold start:

```bash
bun add -g @codefuturist/email-mcp
bun build --compile --minify --bytecode \
  "${BUN_INSTALL:-$HOME/.bun}/install/global/node_modules/@codefuturist/email-mcp/dist/main.js" \
  --outfile ~/.local/bin/email-mcp
```

An installed binary keeps itself current: `email-mcp update` checks the latest
release and — after a confirmation, a sha256 check against the release's
checksums file, and (when the `gh` CLI is present) a provenance-attestation
check — atomically replaces itself. `--check` only reports (exit code 1 =
update available), `--yes` skips the prompt for scripts. npm- and mise-managed
installs are recognized and pointed at `npm install -g …@latest` /
`mise upgrade` instead of being overwritten.

`server install` from the binary points the launchd login item at it. Requires the
bundled imapflow patch (`patches/`) — imapflow passes `servername: false` to
tls.connect for IP hosts, which Bun's stricter node:tls rejects.

### Docker

No Node.js required — just Docker.

```bash
# Latest stable release
docker pull ghcr.io/codefuturist/email-mcp:latest

# Pin to an exact version (immutable)
docker pull ghcr.io/codefuturist/email-mcp:0.2.3

# Auto-update patches within a minor version
docker pull ghcr.io/codefuturist/email-mcp:0.2

# Track a major version (won't cross breaking-change boundary)
docker pull ghcr.io/codefuturist/email-mcp:0

# Pin to an exact git commit (immutable, CI traceability)
docker pull ghcr.io/codefuturist/email-mcp:sha-abc1234

# Or build from source
docker build -t ghcr.io/codefuturist/email-mcp .
```

> **Tag convention:** Tags follow bare semver (no `v` prefix), matching Docker ecosystem standards (e.g. `node:24`, `nginx:1.25`). The `latest` tag is only updated on stable releases, never pre-releases.

> **Note:** By default, the server uses stdio transport. Config must be created on the host first
> (via `npx @codefuturist/email-mcp setup` or manually) and mounted into the container.

## Usage

### Setup

```bash
# Add an email account interactively (recommended)
# On macOS and Linux this offers to store the password in the OS keychain,
# so config.toml only carries a `keychain:<account>` reference.
email-mcp account add

# Or use the legacy alias
email-mcp setup

# Or create a template config manually
email-mcp config init
```

The setup wizard auto-detects server settings, tests connections, saves config, and outputs the MCP client config snippet.

### Test Connections

```bash
email-mcp test            # all accounts
email-mcp test personal   # specific account
```

### Configure Your MCP Client

The snippets below use the default **stdio** transport, best for local desktop clients. For networked or remote access over **Streamable HTTP**, see [Streamable HTTP (networked)](#streamable-http-networked) below.

**Recommended — use the guided installer** (auto-detects Claude Desktop, Cursor, Windsurf; for VS Code use the manual snippet below):

```bash
email-mcp install
```

Or add manually using the snippets below.

<details>
<summary><strong>Claude Desktop</strong></summary>

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "email": {
      "command": "npx",
      "args": ["-y", "@codefuturist/email-mcp", "stdio"]
    }
  }
}
```
</details>

<details>
<summary><strong>VS Code (GitHub Copilot)</strong></summary>

**Option 1 — Extensions gallery (easiest):**
1. Open the Extensions view (<kbd>⇧⌘X</kbd> / <kbd>Ctrl+Shift+X</kbd>)
2. Search `@mcp email-mcp`
3. Click **Install** (user-wide) or right-click → **Install in Workspace**

**Option 2 — Workspace config** (`.vscode/mcp.json`, committed to source control):

```json
{
  "servers": {
    "email": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@codefuturist/email-mcp", "stdio"]
    }
  }
}
```

**Option 3 — User config** (`settings.json`, applies to all workspaces):

Open the Command Palette → **Preferences: Open User Settings (JSON)** and add:

```json
{
  "mcp": {
    "servers": {
      "email": {
        "type": "stdio",
        "command": "npx",
        "args": ["-y", "@codefuturist/email-mcp", "stdio"]
      }
    }
  }
}
```
</details>

<details>
<summary><strong>Cursor</strong></summary>

Edit `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "email": {
      "command": "npx",
      "args": ["-y", "@codefuturist/email-mcp", "stdio"]
    }
  }
}
```
</details>

<details>
<summary><strong>Windsurf</strong></summary>

Edit `~/.codeium/windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "email": {
      "command": "npx",
      "args": ["-y", "@codefuturist/email-mcp", "stdio"]
    }
  }
}
```
</details>

<details>
<summary><strong>Zed</strong></summary>

Edit `~/.config/zed/settings.json`:

```json
{
  "context_servers": {
    "email": {
      "command": {
        "path": "npx",
        "args": ["-y", "@codefuturist/email-mcp", "stdio"]
      }
    }
  }
}
```
</details>

<details>
<summary><strong>Mistral Vibe</strong></summary>

Add to `~/.vibe/config.toml`:

```toml
[[mcp_servers]]
name = "email-mcp"
transport = "stdio"
command = "npx"
args = ["-y", "@codefuturist/email-mcp", "stdio"]
```

To pass credentials directly instead of using a config file, use the `env` field:

```toml
[[mcp_servers]]
name = "email-mcp"
transport = "stdio"
command = "npx"
args = ["-y", "@codefuturist/email-mcp", "stdio"]
env = { "EMAIL_ACCOUNTS" = "<your-accounts-json>" }
```

MCP tools are exposed as `email-mcp_<tool_name>` (e.g. `email-mcp_list_emails`). Restart Vibe after editing the config.

</details>

<details>
<summary><strong>Docker (any MCP client)</strong></summary>

Run the server in a container — mount your config directory read-only:

```bash
docker run --rm -i \
  -v ~/.config/email-mcp:/home/node/.config/email-mcp:ro \
  -v email-mcp-state:/home/node/.local/state/email-mcp \
  -v email-mcp-cache:/home/node/.cache/email-mcp \
  ghcr.io/codefuturist/email-mcp
```

The config mount can stay read-only, but **state and cache must be persisted**.
The image declares both as volumes, so Docker keeps them in anonymous volumes
if you omit the flags — naming them, as above, is what makes them survive a
`docker run --rm`. State holds the scheduled-email queue: without it, a restart
drops every email scheduled but not yet sent. Cache holds the local mirror,
which is regenerable, so losing that only costs a re-sync.

For MCP client configuration (e.g. Claude Desktop):

```json
{
  "mcpServers": {
    "email": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "~/.config/email-mcp:/home/node/.config/email-mcp:ro",
        "-v", "email-mcp-state:/home/node/.local/state/email-mcp",
        "-v", "email-mcp-cache:/home/node/.cache/email-mcp",
        "ghcr.io/codefuturist/email-mcp"
      ]
    }
  }
}
```
</details>

<details>
<summary><strong>Single-account via environment variables (no config file needed)</strong></summary>

```json
{
  "mcpServers": {
    "email": {
      "command": "npx",
      "args": ["-y", "@codefuturist/email-mcp", "stdio"],
      "env": {
        "MCP_EMAIL_ADDRESS": "you@gmail.com",
        "MCP_EMAIL_PASSWORD": "your-app-password",
        "MCP_EMAIL_IMAP_HOST": "imap.gmail.com",
        "MCP_EMAIL_SMTP_HOST": "smtp.gmail.com"
      }
    }
  }
}
```
</details>

### Always-on server (detached)

The stdio transport lives only as long as an MCP client keeps it open — which also
means the IMAP watcher (and verification catching) stop with it. `email-mcp server`
runs the Streamable HTTP server as a background service instead, iMCP-style:

```bash
email-mcp server start              # detached on http://127.0.0.1:8080/mcp
email-mcp server start --port 3199  # any http flags pass through (--host, --token, …)
email-mcp server start --attach     # foreground instead (Ctrl-C stops)
email-mcp server status             # pid, address, /healthz, uptime
email-mcp server logs -n 50         # tail the daemon log
email-mcp server restart            # reuses the previous flags
email-mcp server stop               # graceful SIGTERM (add --force for SIGKILL)
```

The binding lives in the config file, so a plain `server start` is deterministic:

```toml
[settings.server]
host = "127.0.0.1"
port = 8080
path = "/mcp"
token = ""            # bearer token; empty = no auth (loopback only)
allowed_hosts = []    # Host-header allowlist for reverse proxies
```

Precedence: CLI flags → `EMAIL_MCP_HTTP_*` env → `[settings.server]` → defaults —
for `email-mcp http`, `server start`, and the launchd login item alike. Edit it
interactively with `config edit server` (the token renders masked). `--insecure`
is deliberately flag-only and cannot be persisted.

**Start at login (macOS):** `email-mcp server install` writes a launchd login item
(`com.email-mcp.server`, RunAtLoad + KeepAlive) running `email-mcp http` with no
flags — the config file is its single source of truth across reboots and crashes.
`server status` recognizes the launchd mode; `server uninstall` removes it.

State lives in `$XDG_STATE_HOME/email-mcp/daemon.json`, logs in `server.log` next to
it (rotated at 5 MB). `stop` only ever signals a process whose command line is
verifiably this server (PID-reuse safe). Point HTTP-capable MCP clients at
`http://127.0.0.1:8080/mcp`; binding non-loopback hosts still requires a token.

### Streamable HTTP (networked)

By default the server speaks MCP over **stdio**, ideal for local desktop clients (see the snippets above). For networked or remote access, run it as a **Streamable HTTP** server instead:

```bash
email-mcp http --port 8080
```

This serves MCP at `http://127.0.0.1:8080/mcp`, with a health probe at `GET /healthz`.

#### Flags & environment variables

| Flag | Environment variable | Default | Description |
|------|----------------------|---------|-------------|
| `--host <addr>` | `EMAIL_MCP_HTTP_HOST` | `127.0.0.1` | Address to bind |
| `--port <n>` | `EMAIL_MCP_HTTP_PORT` | `8080` | Port to listen on |
| `--path <path>` | `EMAIL_MCP_HTTP_PATH` | `/mcp` | HTTP path serving MCP |
| `--token <secret>` | `EMAIL_MCP_HTTP_TOKEN` | — | Require `Authorization: Bearer <secret>` on every request |
| `--allowed-hosts a,b,c` | `EMAIL_MCP_HTTP_ALLOWED_HOSTS` | _loopback names + bind host_ | Comma-separated `Host` header allowlist (DNS-rebinding protection); `*` disables the check |
| `--insecure` | — | `false` | Allow binding a non-loopback host without a token |

#### Security

- **Token auth** — When a token is set, every request must send `Authorization: Bearer <token>`.
- **Non-loopback bind guard** — Binding a non-loopback host (e.g. `0.0.0.0`) **without** a token is refused unless `--insecure` is passed. Use `--insecure` only when TLS and authentication are terminated by an upstream reverse proxy.
- **DNS-rebinding protection** — The `Host` header is validated against an allowlist (loopback names plus the bind host by default). Set `EMAIL_MCP_HTTP_ALLOWED_HOSTS` to your public domain, or `*` to disable the check when a proxy already enforces it.

#### Client configuration

For clients that support the Streamable HTTP transport:

```json
{
  "mcpServers": {
    "email": {
      "type": "streamable-http",
      "url": "http://127.0.0.1:8080/mcp"
    }
  }
}
```

When a token is configured, add an `Authorization: Bearer <token>` header if your client supports custom headers.

#### Docker

```bash
docker compose --profile http up
```

Requires `EMAIL_MCP_HTTP_TOKEN` to be set; the image `EXPOSE`s port `8080`.

### CLI Commands

```
email-mcp [command]

Commands:
  stdio                     Run as MCP server over stdio (default)
  http                      Run as MCP server over Streamable HTTP (networked)
  server start [--attach]   Start an always-on HTTP server (detached by default)
  server stop [--force]     Stop the detached server
  server status             Show pid, address, health, uptime (exit 1 if stopped)
  server restart            Stop and start again (reuses previous flags)
  server logs [-n N]        Show the last N daemon log lines
  server install            Install as macOS login item (launchd, survives reboots)
  server uninstall          Remove the login item and stop the server
  account list              List all configured accounts
  account add               Add a new email account interactively
  account edit [name]       Edit an existing account
  account delete [name]     Remove an account
  setup                     Alias for 'account add'
  test                      Test connections for all or a specific account
  open <id> [--print]       Open an email in the native mail client via its message: link
                            (macOS; --print or other platforms print the URL instead)
  install                   Register email-mcp with MCP clients interactively
  install status            Show registration status for detected clients
  install remove            Unregister email-mcp from MCP clients
  config show               Show config (passwords masked)
  config edit [section]     Interactive settings editor (general, server, send, attachments,
                            scheduler, watcher, verification, cache, hooks, alerts)
  config validate           Check syntax, schema, typo'd keys, and cross-setting consistency
  completion zsh|bash|fish  Print shell completion script (accounts and sections complete dynamically)
  config path               Print config file path
  config init               Create template config
  scheduler check           Process pending scheduled emails
  scheduler list            Show all scheduled emails
  scheduler install         Install OS-level scheduler (launchd/crontab)
  scheduler uninstall       Remove OS-level scheduler
  scheduler status          Show scheduler installation status
  cache status [--json]     Show cache size, contents, coverage and freshness
  cache clear [--account N] Delete cached mail/attachments and free the disk space