# MCP Plugins

This plugin uses three MCP servers. All credentials are read from environment variables — **never hardcoded**.

---

## Plugins

### 1. Figma (`figma-developer-mcp`)

Reads Figma designs linked in Jira tickets.

**Package:** [`figma-developer-mcp`](https://www.npmjs.com/package/figma-developer-mcp)

**What it provides:**
- `get_figma_data` — fetch frames, components, layout, copy from a Figma file/node
- `download_figma_images` — export images from Figma nodes

**Credential needed:**
| Variable | Where to get it |
|----------|----------------|
| `FIGMA_API_KEY` | Figma → Settings → Account → Personal access tokens → Generate new token |

---

### 2. Atlassian (`atlassian-mcp`)

Fetches Jira ticket details, description, acceptance criteria, and linked resources.

**Package:** [`atlassian-mcp`](https://www.npmjs.com/package/atlassian-mcp)

**What it provides:**
- Jira: get issue, search issues, get project
- Confluence: get page, search content

**Credentials needed:**
| Variable | Where to get it |
|----------|----------------|
| `ATLASSIAN_API_TOKEN` | https://id.atlassian.com/manage-profile/security/api-tokens → Create API token |
| `ATLASSIAN_EMAIL` | Your Atlassian account email |
| `ATLASSIAN_DOMAIN` | e.g. `yourcompany.atlassian.net` |

---

### 3. GitHub (`api.githubcopilot.com/mcp/`)

Used for raising PRs via `gh` CLI — authentication via GitHub PAT.

**What it provides:**
- GitHub REST API access (repos, PRs, issues)

**Credential needed:**
| Variable | Where to get it |
|----------|----------------|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | GitHub → Settings → Developer settings → Personal access tokens → Generate new token (needs `repo` scope) |

---

## Installation

### Step 1 — Copy MCP settings

```bash
cp mcp/settings.json ~/.claude/settings.json
```

If you already have a `~/.claude/settings.json`, merge the `mcpServers` block into it instead of replacing the whole file.

### Step 2 — Export environment variables

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# Figma
export FIGMA_API_KEY="figd_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# GitHub
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Atlassian / Jira
export ATLASSIAN_API_TOKEN="ATATT3xFfGF0xxxxxxxxxxxxxxxxxxxx"
export ATLASSIAN_EMAIL="you@yourcompany.com"
export ATLASSIAN_DOMAIN="yourcompany.atlassian.net"
```

Then reload your shell:

```bash
source ~/.zshrc
```

### Step 3 — Verify MCP servers are connected

Start a Claude Code session and check the MCP status:

```
/mcp
```

You should see `figma`, `github`, and `atlassian` listed as connected.

---

## How credentials are referenced

The `settings.json` uses `${VAR_NAME}` placeholders. Claude Code resolves these from your shell environment at startup — no secrets are ever stored in the file itself.

```json
{
  "mcpServers": {
    "figma": {
      "env": { "FIGMA_API_KEY": "${FIGMA_API_KEY}" }
    }
  }
}
```
