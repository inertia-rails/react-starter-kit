import { createInertiaApp } from "@inertiajs/react"
import { type ReactNode, createElement } from "react"
import { createRoot } from "react-dom/client"

import { initializeTheme } from "@/hooks/use-appearance"
import PersistentLayout from "@/layouts/persistent-layout"

// Temporary type definition, until @inertiajs/react provides one
interface ResolvedComponent {
  default: ReactNode & { layout?: (page: ReactNode) => ReactNode }
}

const appName = (import.meta.env.VITE_APP_NAME ?? "Rails") as string

void createInertiaApp({
  // Set default page title
  // see https://inertia-rails.dev/guide/title-and-meta
  //
  title: (title) => title ? `${title} - ${appName}` : appName,

  resolve: (name) => {
    const pages = import.meta.glob<ResolvedComponent>("../pages/**/*.tsx", {
      eager: true,
    })
    const page = pages[`../pages/${name}.tsx`]
    if (!page) {
      console.error(`Missing Inertia page component: '${name}.tsx'`)
    }

    // To use a default layout, import the Layout component
    // and use the following line.
    // see https://inertia-rails.dev/guide/pages#default-layouts
    //
    page.default.layout ??= (page) =>
      createElement(PersistentLayout, null, page)

    return page
  },

  setup({ el, App, props }) {
    // Uncomment the following to enable SSR hydration:
    // if (el.hasChildNodes()) {
    //   hydrateRoot(el, createElement(App, props))
    //   return
    // }
    createRoot(el).render(createElement(App, props))
  },

  progress: {
    color: "#4B5563",
  },
}).catch((error) => {
  // This ensures this entrypoint is only loaded on Inertia pages
  // by checking for the presence of the root element (#app by default).
  // Feel free to remove this `catch` if you don't need it.
  if (document.getElementById("app")) {
    throw error
  } else {
    console.error(
      "Missing root element.\n\n" +
        "If you see this error, it probably means you loaded Inertia.js on non-Inertia pages.\n" +
        'Consider moving <%= vite_typescript_tag "inertia" %> to the Inertia-specific layout instead.',
    )
  }
})

// This will set light / dark mode on load...
initializeTheme()
