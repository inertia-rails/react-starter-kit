---
name: inertia-rails-react-builder
description: Build and refactor Rails applications that use inertia_rails with Inertia.js React pages. Use this skill when creating or updating Rails + Inertia features, wiring React page components to Rails controllers, implementing Inertia forms/validation/navigation, configuring SSR/code splitting, or writing integration tests for Inertia responses. Apply only for React frontend work and skip Vue/Svelte implementations.
---

# Inertia Rails React Builder

Read `references/inertia-rails-react-playbook.md` before coding. Use it as the source of truth for setup and API usage.

## Apply scope guard first

- Implement only React adapter patterns (`@inertiajs/react`).
- Skip Vue and Svelte instructions, examples, and dependencies.
- Keep Rails as the backend authority for routing, validation, and redirects.

## Execute standard delivery workflow

1. Confirm app setup.
2. Define server contract.
3. Build React page and navigation.
4. Implement write flows with forms and validation.
5. Add performance and data-loading optimizations.
6. Add tests for Inertia responses.

## 1) Confirm app setup

For new app scaffolding, prefer:

```bash
rails new my_app --javascript=esbuild --css=sass -a propshaft -m https://inertia-rails.dev/inertia_rails.rb
```

For existing apps, ensure `inertia_rails` and client packages are installed (`bin/rails inertia:install`), and verify layout and frontend entrypoint wiring.

## 2) Define server contract

- Add or confirm route and controller action.
- Return Inertia response with explicit component and props:

```ruby
render inertia: "Users/Index", props: { users: User.select(:id, :name) }
```

- Use shared data in `ApplicationController` for auth/context props.
- Prefer explicit, stable prop names over implicit serialization.

## 3) Build React page and navigation

- Create page component under `app/frontend/pages/**` matching controller component path.
- Use `Link` from `@inertiajs/react` for internal navigation.
- Use router visits/reloads for stateful navigation updates.
- Use standard `<a>` only for external links or hard navigations.

## 4) Implement write flows with forms and validation

- Use `<Form>` for straightforward CRUD form posts.
- Use `useForm` when you need controlled state, transforms, or submit lifecycle control.
- Keep validation in Rails; on failure, redirect back with errors so Inertia surfaces them to props.
- Use named error bags when multiple forms share one page.
- After mutating requests (`PUT/PATCH/DELETE`), redirect to a GET endpoint (typically `303 See Other`).

## 5) Add performance and data-loading optimizations

- Use lazy props (`-> { ... }`) for expensive payloads.
- Use `InertiaRails.optional` for props fetched only on partial reload demand.
- Use `InertiaRails.defer` for deferred groups.
- Use partial reloads (`only` / `except`) from the client to avoid re-fetching full payloads.
- Add SSR and code splitting only when the feature requires it.

## 6) Add tests for Inertia responses

- Add request/integration tests for each Inertia endpoint.
- Assert component name and critical props using Inertia Rails test helpers.
- Include tests for validation failure paths and redirect behavior.

## Output expectations

When completing tasks with this skill:
- Deliver both Rails and React changes that compile together.
- Keep prop contracts explicit and documented in code.
- Include tests for happy path and validation errors.
- Call out any setup prerequisites (install commands, SSR entrypoints, or missing dependencies).
