# Manual Install Reference

Default install pattern:

```html
<script type="text/javascript" src="SCRIPT_URL" async="async"></script>
```

Placement:

- Put the script near the top of `<head>`
- Place it just after `<meta>` tags when possible
- Use the shared page shell so it loads on every page, not a page-specific component or one-off template

Do not guess `SCRIPT_URL`.

- Prefer fetching it through the `crazyegg-api` skill using the `currentAccount.scriptUrl` GraphQL path
- If the user provides a full snippet instead of a bare URL, preserve that snippet unless it is clearly malformed

Project targeting:

- Pick the install point that controls the `<head>` across the project
- Prefer a shared layout, template, partial, include, document shell, or equivalent top-level wrapper
- Avoid page-level or component-level installs unless the project truly has no shared page shell

Validation:

- search for `script.crazyegg.com` before editing to avoid duplicates
- prefer one install in the shared document shell over multiple page-level inserts
- preserve any CSP nonce or framework-specific script wrapper already used by the target project

Advanced variant:

Some integrations may require preload tags or framework-specific wrappers. Do not use those by default. The default skill behavior should be the single async script tag unless the user explicitly asks for the richer preload setup.
