# Inertia Rails + React Playbook

Source baseline:
- https://inertia-rails.dev/llms-full.txt
- https://inertia-rails.dev/

Scope:
- Rails backend with `inertia_rails`
- Inertia.js React frontend (`@inertiajs/react`)
- Exclude Vue and Svelte patterns

## 1. Project setup

### New app (recommended bootstrap)
Use the official app template:

```bash
rails new my_app --javascript=esbuild --css=sass -a propshaft -m https://inertia-rails.dev/inertia_rails.rb
```

### Existing Rails app
Install server and client pieces:

```bash
bundle add inertia_rails
bin/rails inertia:install
```

Use package-manager specific installers when needed:

```bash
bin/rails inertia:install:npm
bin/rails inertia:install:yarn
bin/rails inertia:install:pnpm
```

After install, ensure:
- Rails layout includes Inertia tags (`inertia_ssr_head`, `inertia_assets`, `inertia_ssr`)
- JS entrypoint initializes Inertia app
- `respond_to :html, :json, :inertia` is available where needed

## 2. React client bootstrapping

Typical entrypoint:

```jsx
import { createInertiaApp } from '@inertiajs/react'
import { resolvePageComponent } from 'laravel-vite-plugin/inertia-helpers'
import { createRoot } from 'react-dom/client'

createInertiaApp({
  resolve: (name) =>
    resolvePageComponent(
      `./pages/${name}.jsx`,
      import.meta.glob('./pages/**/*.jsx')
    ),
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />)
  },
})
```

Use `.tsx` variants when TypeScript is enabled.

Optional progress bar:

```js
import { InertiaProgress } from '@inertiajs/progress'
InertiaProgress.init()
```

## 3. Rails responses and routing

Render Inertia pages from controllers:

```ruby
render inertia: "Events/Show", props: { event: Event.find(params[:id]) }
```

Routes remain normal Rails routes; keep component names aligned with `app/frontend/pages/**`.

Use controller-wide defaults when useful:

```ruby
class EventsController < ApplicationController
  use_inertia_instance_props

  inertia_share app_name: "My app"
end
```

## 4. Data loading patterns

### Shared data
Define global data once in `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  inertia_share auth: -> {
    if Current.user
      { user: Current.user.slice(:id, :name, :email) }
    else
      { user: nil }
    end
  }
end
```

### Lazy/optional/deferred props
Use lambdas/procs to avoid eager work and reduce payload:

```ruby
render inertia: "Users/Index", props: {
  users: -> { UserResource.collection(User.order(created_at: :desc)) },
  companies: InertiaRails.optional(-> { Company.pluck(:id, :name) }),
  teams: InertiaRails.defer(-> { Team.pluck(:id, :name) })
}
```

### Partial reloads
From React, request only updated props:

```js
router.reload({ only: ['users'] })
router.visit('/users', { only: ['users'] })
```

## 5. Navigation and links

Use React adapter links for SPA-like navigation:

```jsx
import { Link } from '@inertiajs/react'

<Link href="/users">Users</Link>
<Link href="/logout" method="post" as="button">Log out</Link>
```

Use standard `<a>` only for external URLs or full-page escapes.

## 6. Forms and validation

### Declarative form component

```jsx
import { Form } from '@inertiajs/react'

<Form action="/users" method="post">
  <input name="name" />
  <button type="submit">Create user</button>
</Form>
```

### Programmatic form state

```jsx
import { useForm } from '@inertiajs/react'

const form = useForm({ name: '', email: '' })

function submit(e) {
  e.preventDefault()
  form.post('/users')
}
```

### Rails validation flow
- Validate with normal Rails model/controller patterns.
- Redirect back on validation failure.
- Inertia automatically exposes errors in page props.
- For multiple forms on one page, use error bags:

```ruby
redirect_to new_user_url, inertia: { errors: user.errors, error_bag: "createUser" }
```

## 7. Redirects and non-GET semantics

After `PUT/PATCH/DELETE`, return a redirect (commonly `303`) to a GET endpoint:

```ruby
redirect_to users_url, status: :see_other
```

For external navigation:

```ruby
redirect_to inertia_location: "https://example.com"
```

## 8. SSR and code splitting (optional)

SSR entrypoint pattern:

```jsx
import { createInertiaApp } from '@inertiajs/react'
import createServer from '@inertiajs/react/server'
import ReactDOMServer from 'react-dom/server'

createServer((page) =>
  createInertiaApp({
    page,
    render: ReactDOMServer.renderToString,
    resolve: (name) => {
      const pages = import.meta.glob('./pages/**/*.jsx', { eager: true })
      return pages[`./pages/${name}.jsx`]
    },
    setup: ({ App, props }) => <App {...props} />,
  })
)
```

Use dynamic imports with `import.meta.glob` for code splitting where practical.

## 9. Testing

Use Inertia Rails test helpers in integration tests:

```ruby
get users_url
assert_inertia component: "Users/Index"
assert_inertia_props(users: [{ "name" => "Jonathan" }])
```

Use `inertia: true` request format when needed:

```ruby
get user_url(user), headers: { 'X-Inertia' => 'true' }
```

## 10. Practical defaults for new features

For each new page/flow:
1. Add or confirm Rails route and controller action.
2. Return `render inertia:` with explicit prop contract.
3. Create matching React page component under `app/frontend/pages`.
4. Use `Link` or `router.visit` for navigation.
5. Use `useForm` or `<Form>` for writes.
6. Handle validation with redirect plus errors.
7. Add integration assertions for component name and critical props.
