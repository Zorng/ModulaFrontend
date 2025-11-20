# Settings Context

The current Settings page is a lightweight placeholder that lists global preferences (dark mode, language) as "Coming soon". It does not belong to Auth, Policy, or any other vertical module because those modules focus on their own business logic (login flows, policy editing, etc.).

Placing it under `features/common` keeps the architecture consistent:
- It remains a **user-facing feature** (not infrastructure), so it belongs in `features/` rather than `core/`.
- It stays **independent** of Auth/Policy while still being easy to promote into its own module (`features/preferences`, etc.) once real logic/data layers arrive.
- Core stays a toolbox (routing, theming, shared widgets) without being cluttered by placeholder screens, and feature modules depend on core—not the other way around.

When the Settings feature gains real functionality (dark mode toggles, language persistence, notifications), we can spin it into a dedicated module without affecting Auth or Policy.
