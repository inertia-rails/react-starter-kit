import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"
import rails from "rails-vite-plugin"

export default defineConfig({
  ssr: {
    // prebuilds ssr.js so we can drop node_modules from the resulting container
    noExternal: true,
  },
  plugins: [
    react({
      babel: {
        plugins: ["babel-plugin-react-compiler"],
      },
    }),
    tailwindcss(),
    rails({
      sourceDir: "app/frontend",
      ssr: "ssr/ssr.ts",
    }),
  ],
})
