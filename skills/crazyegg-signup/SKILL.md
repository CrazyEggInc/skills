---
name: crazyegg-signup
description: Use this skill when creating Crazy Egg accounts through the browser-owned email-link signup flow. It covers constructing the signup page URL with optional email, first-name, last-name, site, and PAT-name prefill, explains that the user must click Register on the signup page before any email is sent, and documents the final email-link confirmation step before the account is created and redirected into the PAT handoff page.
license: MIT
metadata:
  author: CrazyEgg Inc.
  version: "1.0"
---

# Crazy Egg Signup

Use this skill when the task is to start Crazy Egg signup from known user details or to implement the backend/browser flow behind that signup path.

## Defaults

- Use `scripts/crazyegg-signup.sh` to construct the signup page URL.
- Before using the skill, make sure `rg` and `jq` exist in the environment. If either is missing, determine the current OS first, then install it with the appropriate system method before continuing.
- Treat signup initiation as browser-owned, not API-owned.
- Treat signup as asynchronous and multi-step:
  - opening the signup page has no side effects
  - the signup page sends email only after the user clicks `Register`
  - the email link opens a confirm page
  - the account is created only after the recipient submits the final form
- If you are implementing or updating the signup backend, read `references/implementation-patterns.md`.

## Prerequisites

The bundled script uses the fixed Crazy Egg signup URL:

```bash
https://auth.app.crazyegg.com/signup
```

This skill assumes `rg` and `jq` are available to inspect the current project and build the signup URL. If either command is missing, determine the current OS or distro and install it before continuing. Use the native package manager for that environment, for example:

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

## Workflow

1. Confirm the target email address.
2. Determine the production site URL to send as the `site` prefill param:
   - infer it from the current project when you can do so confidently from deployment config, canonical app config, product docs, or known production metadata
   - if you cannot infer it confidently, ask the user for the production URL
3. If known, also confirm the target first name, last name, and PAT name.
4. Read `references/api-contract.md` if the browser contract is relevant.
5. Construct the signup page URL through the bundled script:

```bash
bash scripts/crazyegg-signup.sh person@example.com Grey Example OpenClaw --site https://example.com
```

6. If the task is operational, open that URL in the browser or give it to the user.
7. Do not claim an email was sent merely because the signup page URL was opened.
8. The user must click `Register` on the signup page before any signup or login email is sent.
9. Do not claim the account exists yet unless the user confirms they completed the final browser form after clicking the email link.
10. If the email already exists, expect the backend to send a generic magic link after the signup-page submit and still continue through the same neutral success/info path.

## Guidance

- Do not guess alternate query fields. The default prefill query params are `email`, `first_name`, `last_name`, required `site`, and optional `pat_name`.
- Prefill is optional only for `first_name`, `last_name`, and `pat_name`. The `site` param should be sent after you either infer it confidently from the current project or ask the user for the production URL.
- If `rg` or `jq` is missing, stop and install it for the current OS before trying the workflow again.
- Opening `/signup` must not send email on GET.
- The signup page should collect `email`, `first_name`, `last_name`, and `site`.
- Prefer the production site URL over staging, preview, localhost, or repository-only guesses.
- If `pat_name` is present, carry it through the signup email-link flow and use it to prefill the dedicated PAT page after registration.
- The email link flow is browser-facing.
- The final confirm page should require explicit user interaction before user creation.
- After successful registration, redirect the user to `/settings/personal-access-token`.
- When a PAT name was provided, add `?pat_name=...&agent_handoff=true` to that redirect so the PAT page opens in the focused agent handoff flow.
- The PAT page must not create a token on GET. In handoff mode, token creation still requires an explicit click on the page.
- In handoff mode, after the explicit create action, the page should show the token once, present a large copy button, tell the user to return to their agent and paste the token, and offer a `Done` link to shell home.
- If the contract changes, update `scripts/crazyegg-signup.sh` and `references/api-contract.md` together.
- If implementing this flow, use the token, first/last-name, site, PAT-name, and email guidance in `references/implementation-patterns.md`.
