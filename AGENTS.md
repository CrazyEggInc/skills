# AGENTS.md

This repository contains installable Agent Skills for Crazy Egg services.

## Source Guidance

When creating or updating skills in this repository, follow the Agent Skills quickstart and its linked best-practice guidance:

- `https://agentskills.io/skill-creation/quickstart.md`

## Required Conventions

- A skill is a folder under `skills/<skill-name>/` containing `SKILL.md`.
- The frontmatter `name` must match the folder name.
- The `description` must clearly say when the skill should activate.
- The body should give concrete instructions the agent can execute, not just background prose.
- Keep skills small, explicit, and self-contained.
- Bundle helper material with the skill in `scripts/`, `references/`, and `assets/` instead of assuming external context.
- Do not make one skill depend on another skill's internal files or paths. If a skill needs another skill's capability, instruct the agent to use that skill by name, or bundle the required helper material locally.
- Prefer progressive disclosure: put activation guidance in frontmatter, deeper instructions in the body, and detailed reference material in bundled files.

## Repository Expectations

- Keep examples accurate and runnable.
- Document required environment variables in the skill.
- If a skill requires `rg` or `jq`, tell the agent to check for them before use. If either is missing, the skill must instruct the agent to install it with the method that matches the current OS or distro instead of failing silently or assuming a package manager.
- Prefer minimal scripts and deterministic workflows.
- Update `README.md` when adding or materially changing a public skill.
- Use MIT-compatible content only.

## Note

This repository is public for distribution, not public contribution.
