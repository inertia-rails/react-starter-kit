# Inertia Rails React Starter Kit

A modern full-stack starter application with Rails backend and React frontend using Inertia.js based on the [Laravel Starter Kit](https://github.com/laravel/react-starter-kit).

## About this repo

This starter kit is generated output of [inertia-rails/generator](https://github.com/inertia-rails/generator):
each generator release regenerates the app and opens an automated sync PR here, so most files in this repo
are overwritten on every sync. **To contribute changes to the app itself, open a PR against the generator** —
only this README and the deploy workflow are kit-owned.

Prefer different options (framework, JavaScript instead of TypeScript, feature set)? Generate your own app:

```sh
rails new myapp -m https://raw.githubusercontent.com/inertia-rails/generator/dist/template.rb
```

## Features

- [Inertia Rails](https://inertia-rails.dev) & [Vite Rails](https://vite-ruby.netlify.app) setup
- [React](https://react.dev) frontend with TypeScript & [shadcn/ui](https://ui.shadcn.com) component library
- User authentication system (based on [Authentication Zero](https://github.com/lazaronixon/authentication-zero))
- [Kamal](https://kamal-deploy.org/) for deployment
- Optional SSR support

See also:
- [Svelte Starter Kit](https://github.com/inertia-rails/svelte-starter-kit) for Inertia Rails with Svelte
- [Vue Starter Kit](https://github.com/inertia-rails/vue-starter-kit) for Inertia Rails with Vue

<a href="https://evilmartians.com/?utm_source=inertia-rails-react-starter-kit&utm_campaign=project_page">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Built by Evil Martians" width="236" height="54">
</a>

## Setup

1. Clone this repository
2. Setup dependencies & run the server:
   ```bash
   bin/setup
   ```
3. Open http://localhost:3000

## Enabling SSR

This starter kit ships SSR-ready but turned off. The Puma plugin
([`plugin :inertia_ssr`](config/puma.rb)) manages the Node.js renderer
in-process — no separate accessory required.

To turn SSR on, flip two switches:

1. Set `config.ssr_enabled = true` in [`config/initializers/inertia_rails.rb`](config/initializers/inertia_rails.rb).
2. Build the image with `SSR_ENABLED=true` so the SSR bundle ships
   alongside the app. Two ways:

   **With Kamal** — add to [`config/deploy.yml`](config/deploy.yml):

   ```yml
   builder:
     args:
       SSR_ENABLED: true
   ```

   **By hand** — pass the build arg directly:

   ```bash
   docker build --build-arg SSR_ENABLED=true -t react_starter_kit .
   ```

That's it. Puma boots the SSR process automatically when
`ssr_enabled` is true, and Inertia falls back to client-side
rendering if it ever fails (see `config.on_ssr_error`).

In development, flipping `ssr_enabled` is enough — Vite serves SSR
via its own dev endpoint with HMR. The Docker build arg only matters
for production images.

## License

The project is available as open source under the terms of the [MIT License](LICENSE).
