---
name: crazyegg-api
description: Use Crazy Egg's GraphQL API through the bundled schema snapshot and `scripts/crazyegg.sh`. Use when inspecting the public GraphQL schema, finding types or fields, or sending authenticated GraphQL queries and mutations. For live API calls, first check whether a Crazy Egg PAT is already available, then determine whether the user already has an account, guide signup through `crazyegg-signup` if needed, ask for the PAT after signup or PAT creation, and save it locally with `scripts/crazyegg.sh pat-save`.
license: MIT
compatibility: Requires bash, curl, jq, and rg. Network access plus a Crazy Egg PAT are required only for live `gql` requests. The PAT may come from `CRAZYEGG_PAT` or a saved PAT file.
metadata:
  author: CrazyEgg Inc.
  version: "1.0"
---

# Crazy Egg GraphQL API

Use this skill when you need to inspect or call Crazy Egg's public GraphQL API.

## Defaults

- Use `scripts/crazyegg.sh` as the default interface.
- Before using the skill, make sure `rg` and `jq` exist in the environment. If either is missing, determine the current OS first, then install it with the appropriate system method before continuing.
- For any live API task, start with `bash scripts/crazyegg.sh pat-status`.
- Prefer a saved PAT or `CRAZYEGG_PAT` over asking the user to re-enter credentials each time.
- Use the bundled schema snapshot before making live requests.
- Read raw schema files only when the script output is not enough.
- If no PAT is available, do not jump straight to GraphQL examples. First determine whether the user already has a Crazy Egg account.
- If the user does not have an account, use the `crazyegg-signup` skill to guide signup before asking for a PAT.
- After signup or PAT creation, ask for the PAT and save it with `bash scripts/crazyegg.sh pat-save ce_pat_...`.

## Prerequisites

This skill assumes `rg` and `jq` are available. If either command is missing, determine the current OS or distro and install it before continuing. Use the native package manager for that environment, for example:

```bash
# macOS
brew install ripgrep jq

# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y ripgrep jq

# Fedora
sudo dnf install -y ripgrep jq

# Arch
sudo pacman -S --needed ripgrep jq

# Windows
winget install BurntSushi.ripgrep.MSVC jqlang.jq
```

Live GraphQL requests need a Crazy Egg personal access token. The script can use either:

```bash
export CRAZYEGG_PAT="ce_pat_..."
```

or a saved token at:

```bash
~/.config/crazyegg/pat
```

The saved path can be overridden with:

```bash
export CRAZYEGG_PAT_FILE="$XDG_CONFIG_HOME/crazyegg/pat"
```

The script saves this file with owner-only permissions. `CRAZYEGG_PAT` still takes precedence when both are present.

Optional:

```bash
export CRAZYEGG_GQL_URL="https://api.crazyegg.com/api"
```

Get a PAT from `https://auth.app.crazyegg.com/settings`. Keep the `ce_pat_` prefix.

If no PAT is available and the task requires live API access, first ask whether the user already has a Crazy Egg account. If not, switch to the `crazyegg-signup` skill to guide account signup. After signup or PAT creation, ask the user for the PAT and save it with `pat-save`. Do not invent placeholder tokens and do not present unauthenticated schema inspection as equivalent to a live API call.

## Bundled Resources

- `scripts/crazyegg.sh`: default entrypoint for schema inspection, PAT status/save helpers, and live GraphQL requests
- `assets/schema.json`: machine-friendly schema snapshot used by the script
- `assets/schema.graphql`: SDL snapshot for exact text lookup and grep-style search

## Workflow

1. Before any live request, check PAT status:

```bash
bash scripts/crazyegg.sh pat-status
```

2. If PAT status reports `source: "environment"` or `source: "saved_file"`, continue normally. The script will load the saved PAT automatically for `gql`.

3. If the task is to fetch the Crazy Egg install URL, use:

```bash
bash scripts/crazyegg.sh current-script-url
```

4. If no PAT is available, ask whether the user already has a Crazy Egg account.

5. If the user does not have an account, switch to the `crazyegg-signup` skill and guide signup first. Do not assume they know where PATs come from.

6. If the user has an account but no PAT, direct them to `https://auth.app.crazyegg.com/settings` to create one.

7. After signup or PAT creation, ask the user for the PAT and save it:

```bash
bash scripts/crazyegg.sh pat-save ce_pat_...
```

8. Start with the local schema snapshot:

```bash
bash scripts/crazyegg.sh schema-summary
bash scripts/crazyegg.sh root query
bash scripts/crazyegg.sh type Site
bash scripts/crazyegg.sh field sessionInfo
bash scripts/crazyegg.sh search recordings
```

9. If you need the exact SDL or surrounding comments, inspect `assets/schema.graphql`.

10. Execute live operations through the script:

```bash
bash scripts/crazyegg.sh gql 'query { sessionInfo { isAuthenticated } }' | jq .
```

11. For multi-line operations, save the query and variables to files and pass the file paths:

```bash
bash scripts/crazyegg.sh gql query.graphql variables.json | jq .
```

12. Before using mutations, inspect the mutation root and confirm the token is not read-only:

```bash
bash scripts/crazyegg.sh root mutation
```

## Guidance

- Prefer `type`, `field`, and `root` over opening the full schema JSON.
- Prefer `search` when you only need to locate names or descriptions quickly.
- If `rg` or `jq` is missing, stop and install it for the current OS before trying the script again.
- For live tasks, never assume the user already has an account or already knows where PATs are created.
- If PAT status is missing, explicitly branch:
  - ask whether they already have a Crazy Egg account
  - if not, use `crazyegg-signup`
  - after signup or PAT creation, ask for the PAT
  - save it with `pat-save` before continuing
- Keep requests narrow. Ask for the minimum fields needed.
- Pipe live results to `jq` for filtering and formatting.
- Do not print or echo the PAT back unnecessarily after the user provides it.
- Treat GraphQL `errors` as authoritative.
- If the live API disagrees with the bundled snapshot, trust the live response and note that the snapshot may be stale.
- If the user needs live API access but lacks a PAT, use the `crazyegg-signup` skill to unblock signup, then ask for and save the PAT rather than stopping at the missing credential.

## Quick Examples

Check whether a PAT is already available:

```bash
bash scripts/crazyegg.sh pat-status
```

Save a PAT for later reuse:

```bash
bash scripts/crazyegg.sh pat-save ce_pat_...
```

Fetch the current account's install URL:

```bash
bash scripts/crazyegg.sh current-script-url
```

Check auth:

```bash
bash scripts/crazyegg.sh gql 'query { sessionInfo { isAuthenticated hasSharedItems isImpersonated } }' | jq .
```

Inspect viewer/account context:

```bash
bash scripts/crazyegg.sh gql 'query { me { email name accounts { id name isCurrent isReadOnly } } }' | jq .
```

Inspect a type before writing a query:

```bash
bash scripts/crazyegg.sh type MeDetails
```
