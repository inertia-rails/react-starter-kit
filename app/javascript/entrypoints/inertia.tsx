import { createInertiaApp } from "@inertiajs/react"

import { initializeTheme } from "@/hooks/use-appearance"
import PersistentLayout from "@/layouts/persistent-layout"

const appName = import.meta.env.VITE_APP_NAME ?? "React Starter Kit"

void createInertiaApp({
  title: (title) => (title ? `${title} - ${appName}` : appName),
  strictMode: true,
  pages: "../pages",
  layout: () => PersistentLayout,
  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    visitOptions: () => ({
      queryStringArrayFormat: "brackets",
    }),
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
        'Consider moving <%= vite_tags "inertia.tsx" %> to the Inertia-specific layout instead.',
    )
  }
})

// This will set light / dark mode on load...
initializeTheme()
