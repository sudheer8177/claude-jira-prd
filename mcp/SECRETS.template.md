# SECRETS

> Copy this file to `~/.claude/SECRETS.md` and fill in your real values.
> This file is gitignored — **never commit it with real values**.

---

## GitHub

| Key | Value |
|-----|-------|
| `GITHUB_PERSONAL_ACCESS_TOKEN` | `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx` |

**Get it:** GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token
**Scopes needed:** `repo`, `read:org`

---

## Figma

| Key | Value |
|-----|-------|
| `FIGMA_API_KEY` | `figd_xxxxxxxxxxxxxxxxxxxxxxxxxxxx` |

**Get it:** Figma → Account Settings → Personal access tokens → Generate new token

---

## Atlassian (Jira)

| Key | Value |
|-----|-------|
| `ATLASSIAN_API_TOKEN` | `ATATT3xFfGF0xxxxxxxxxxxxxxxxxxxx` |
| `ATLASSIAN_EMAIL` | `you@yourcompany.com` |
| `ATLASSIAN_DOMAIN` | `yourcompany.atlassian.net` |

**Get it:** https://id.atlassian.com/manage-profile/security/api-tokens → Create API token

---

## Shell exports (add to ~/.zshrc or ~/.bashrc)

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export FIGMA_API_KEY="figd_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export ATLASSIAN_API_TOKEN="ATATT3xFfGF0xxxxxxxxxxxxxxxxxxxx"
export ATLASSIAN_EMAIL="you@yourcompany.com"
export ATLASSIAN_DOMAIN="yourcompany.atlassian.net"
```
