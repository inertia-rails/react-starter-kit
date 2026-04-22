import inertia from "@inertiajs/vite"
import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"

export default defineConfig(({ command }) => ({
  ssr:
    command === "build"
      ? { noExternal: true } // prebuild ssr.js so we can drop node_modules from the container
      : undefined,
  plugins: [
    react({
      babel: {
        plugins: ["babel-plugin-react-compiler"],
      },
    }),
    tailwindcss(),
    RubyPlugin(),
    inertia({
      ssr: {
        entry: "./entrypoints/inertia.tsx",
      },
    }),
  ],
}))
