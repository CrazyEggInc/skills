# Email-Link Signup Implementation Patterns

Use these patterns when building or revising the backend behind the browser-owned signup flow.

Core flow:

1. Render a logged-out signup page.
2. Accept optional `email`, `first_name`, `last_name`, required `site`, and optional `pat_name` query params for prefill.
3. Do not send email on GET.
4. On explicit signup-page submit, validate and normalize the email.
5. Validate first name, last name, and site.
6. If the email already belongs to an existing user, send the generic magic-link login email and continue to the same neutral success/info page.
7. If the email is new, generate a single-use, time-limited signup token.
8. Store pre-signup metadata such as `first_name`, `last_name`, `site`, and `pat_name` in the signup token data.
9. Send an email containing a signup link with that token.
10. When the link is clicked, verify the token and render a browser confirmation page.
11. Prefill the final confirmation form from token metadata when present.
12. On explicit final form submit, verify and atomically claim the token, collect first name, last name, and site, create the account, and create or reuse the site for that registrable domain.
13. Mark the token as consumed so the link cannot be reused.
14. Redirect the user to the dedicated PAT page at `/settings/personal-access-token`.
15. If `pat_name` is present, preserve it in the redirect query and add `agent_handoff=true` so the PAT page opens in the focused handoff flow.
16. In PAT handoff mode, do not create a token on GET. Require an explicit button click before persisting the token.

Recommended behavior:

- Make the signup-page submit idempotent for repeated requests to the same email.
- Do not reveal whether the email already has an account.
- Use a 30 minute signup-token expiry.
- Record delivery and click events separately from account creation.
- Require explicit user interaction on the signup page before sending email.
- Require explicit user interaction on the final confirm page so email-link scanners do not create accounts automatically.
- When creating a new user, assign payment plan `246`.
- Build the stored user `name` from `first_name` and `last_name`.
- Infer the production site URL from the current project when you can do so confidently; otherwise ask the user for it before constructing the signup URL.
- Send the production URL as the `site` prefill param and normalize it to the registrable domain when creating the Crazy Egg site.
- Allow the final confirmation page to edit first name, last name, and site before account creation.
- Use the fixed auth signup entry point `https://auth.app.crazyegg.com/signup`; do not make it configurable through environment overrides.

Suggested browser semantics:

- `GET /signup` renders the page
- `GET /signup?...` pre-fills `email`, `first_name`, `last_name`, `site`, and optional `pat_name`
- `POST /signup/email-link` sends the signup or magic-link email
- `GET /signup/email-link/confirm?token=...` renders the final confirmation page
- `POST /signup/email-link/register` creates the account

Suggested abuse controls:

- CSRF protection on browser submits
- challenge or anti-bot protection on signup-page submit
- resend throttle per normalized email
- rate limiting per IP or subnet
- generic success/info pages for existing and unknown states

Suggested link semantics:

- the link should be single use
- the GET link should render a confirmation page, not create the account
- the POST from that page should require `site` and allow `first_name` and `last_name`
- redirect successful registrations to `/settings/personal-access-token`
- when `pat_name` is available, add `?pat_name=...&agent_handoff=true` to that redirect
- keep PAT creation browser-owned and explicit; opening the redirected PAT page must not mint a token yet
- on invalid or expired tokens, show a resend path rather than a dead-end error
