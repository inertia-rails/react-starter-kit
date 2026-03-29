import { createInertiaApp } from "@inertiajs/react"

import PersistentLayout from "@/layouts/persistent-layout"

const appName = import.meta.env.VITE_APP_NAME ?? "React Starter Kit"

void createInertiaApp({
  title: (title) => (title ? `${title} - ${appName}` : appName),

  pages: "../pages",

  layout: () => [PersistentLayout],

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
  },
})
