# Browser Signup Contract

This skill assumes a browser-owned signup flow with the following minimum contract:

- Entry point: browser navigation to `https://auth.app.crazyegg.com/signup`
- Transport: URL with optional query params for prefill
- Default method for prefill: `GET`
- Default query params:
  - `email=person@example.com`
  - `first_name=Grey`
  - `last_name=Example`
  - `site=https://example.com`
  - `pat_name=OpenClaw`
- Output of the bundled script: a signup page URL, not an email-delivery API response

Expected product behavior:

- The entry point is a logged-out signup page, not a JSON API.
- Opening the signup page does not send email.
- The signup page displays `email`, `first_name`, `last_name`, and `site` fields.
- The page may prefill those fields from query params when present.
- The `site` value should be the user's production URL, not localhost or a preview URL.
- The page may also accept optional `pat_name` so the post-signup PAT page can prefill the token name.
- The user must click `Register` on the signup page before any signup or magic-link email is sent.
- If the email does not belong to an existing user, the browser submit sends a signup email.
- If the email already exists, the browser submit sends the normal magic-link login email instead.
- Both cases should continue to the same neutral success/info page.
- The signup email contains a link to a browser confirmation page.
- Clicking that link does not create the account by itself.
- The recipient must explicitly submit the final form before the account is created.
- The final form should allow first name, last name, and site to be reviewed or edited.
- After successful registration, the user should be redirected to `/settings/personal-access-token`.
- When `pat_name` is provided, the redirect should include `pat_name` and `agent_handoff=true`.
- Loading the PAT page must not create a token on GET, even in handoff mode.
- In handoff mode, token creation should happen only after an explicit user click on the page.

Suggested example URL:

```text
https://auth.app.crazyegg.com/signup?email=person@example.com&first_name=Grey&last_name=Example&site=https%3A%2F%2Fexample.com&pat_name=OpenClaw
```

The bundled script intentionally avoids assuming anything about browser automation or HTTP responses. If the real flow changes path names or prefill query params, update the script and this file together.
