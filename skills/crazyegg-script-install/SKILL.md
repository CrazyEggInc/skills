---
name: crazyegg-script-install
description: Use this skill when a user wants the Crazy Egg tracking script added to a website or app. It covers finding the shared document shell or equivalent page wrapper, inserting the canonical async script in the head so it loads on every page, avoiding duplicate installs, and applying the install automatically in whatever project the user points to.
license: MIT
metadata:
  author: CrazyEgg Inc.
  version: "1.0"
---

# Crazy Egg Script Install

Use this skill when the user wants you to add the Crazy Egg tracking script to a project they point you at.

## Defaults

- Read `references/manual-install.md` before editing.
- Patch the project directly when the correct file can be identified.
- Prefer the simple async script tag unless the task explicitly requires the advanced preload variant.
- Use the `crazyegg-api` skill to fetch the current account script URL (`currentAccount.scriptUrl` GraphQL field) instead of asking the user to paste install code.

## Workflow

1. Find the shared document shell, layout, template, or equivalent place that controls the head for every page.
2. Use the `crazyegg-api` skill to fetch the current account script URL. Do not guess account-specific URLs.
3. Insert the script near the top of `<head>`, just after existing `<meta>` tags when possible.
4. Avoid duplicate installs by searching for `script.crazyegg.com` or the exact script URL before editing.
5. Verify the final code path is part of the page shell rendered on every page, not a leaf component or one-off template.

## Guidance

- Choose the install point that makes the script load on every page for the current project.
- Prefer a shared document template, layout, head include, or equivalent top-level wrapper over page-specific files.
- Preserve existing script ordering and formatting.
