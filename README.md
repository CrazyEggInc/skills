# Crazy Egg Skills

Reusable LLM skills for working with Crazy Egg services, APIs, and installation flows.

This repository is meant to be installed into a compatible skills-enabled agent with:

```bash
npx skills add CrazyEggInc/skills
```

## What's Here

This repo currently ships three skills:

| Skill                     | Purpose                                                                      | Bundled Resources                                     |
| ------------------------- | ---------------------------------------------------------------------------- | ----------------------------------------------------- |
| `crazyegg-api`            | Inspect the Crazy Egg GraphQL schema and run authenticated GraphQL requests. | Schema snapshots, `scripts/crazyegg.sh`               |
| `crazyegg-script-install` | Add the Crazy Egg tracking script to a website or frontend codebase.         | Install guidance reference                            |
| `crazyegg-signup`         | Drive the browser-owned Crazy Egg signup flow from known user details.       | URL builder script, API and implementation references |

## Repository Layout

Each skill lives in its own directory under `skills/`:

```text
skills/
  <skill-name>/
    SKILL.md
    assets/
    references/
    scripts/
```

- `SKILL.md` contains the skill definition, defaults, workflow, and guidance.
- `scripts/` contains helper scripts an agent can run directly.
- `references/` contains deeper implementation notes or operational guidance.
- `assets/` contains bundled data files such as schema snapshots.

## Formatting And Checks

Run these from the repo root:

```bash
nix fmt
nix flake check
```

- `nix fmt` formats Markdown with Prettier and shell scripts with `shfmt`.
- `nix flake check` verifies Markdown formatting, shell formatting, and `shellcheck`.

## Skill Notes

### `crazyegg-api`

Use this skill when an agent needs to inspect Crazy Egg's public GraphQL schema or send live GraphQL operations.

- Starts live access by checking PAT status before asking the user to run queries.
- If no PAT is available, asks whether the user already has a Crazy Egg account before branching to signup.
- Uses `crazyegg-signup` to guide signup, then asks for the PAT and can save it locally for reuse.
- Starts from bundled schema snapshots before making live requests.
- Includes `skills/crazyegg-api/scripts/crazyegg.sh` for schema lookup, PAT management, and `gql` requests.
- Live requests use `CRAZYEGG_PAT` or a saved PAT file at `~/.config/crazyegg/pat`.

Example:

```bash
bash skills/crazyegg-api/scripts/crazyegg.sh pat-status
bash skills/crazyegg-api/scripts/crazyegg.sh pat-save ce_pat_...
bash skills/crazyegg-api/scripts/crazyegg.sh current-script-url
bash skills/crazyegg-api/scripts/crazyegg.sh schema-summary
bash skills/crazyegg-api/scripts/crazyegg.sh gql 'query { sessionInfo { isAuthenticated } }' | jq .
```

### `crazyegg-script-install`

Use this skill when an agent needs to add the Crazy Egg tracking script to an app.

- Helps find the correct shared HTML/layout file.
- Fetches the current account script URL through the bundled GraphQL helper when a PAT is available.
- Prefers the canonical async script tag near the top of `<head>`.
- Avoids duplicate installs and page-level placement mistakes.

### `crazyegg-signup`

Use this skill when an agent needs to start or implement Crazy Egg's email-link signup flow.

- Treats signup as browser-owned and multi-step.
- Includes `skills/crazyegg-signup/scripts/crazyegg-signup.sh` to build prefilled signup URLs.
- Documents the neutral success path for both new and existing emails.
- Documents the post-signup redirect into the dedicated PAT handoff page.

Example:

```bash
bash skills/crazyegg-signup/scripts/crazyegg-signup.sh person@example.com Grey Example OpenClaw --site https://example.com
```

## Maintenance

This repository is published for installation and reuse. We are not accepting public contributions at this time.

Repo-specific authoring guidance for maintainers lives in [`AGENTS.md`](AGENTS.md).

## License

MIT. See [`LICENSE`](LICENSE).
