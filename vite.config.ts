import inertia from "@inertiajs/vite"
import babel from "@rolldown/plugin-babel"
import tailwindcss from "@tailwindcss/vite"
import react, { reactCompilerPreset } from "@vitejs/plugin-react"
import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"

export default defineConfig(({ command }) => ({
  ssr:
    command === "build"
      ? { noExternal: true } // prebuild ssr.js so we can drop node_modules from the container
      : undefined,
  plugins: [
    react(),
    babel({ presets: [reactCompilerPreset()] }),
    tailwindcss(),
    RubyPlugin(),
    inertia({
      ssr: {
        entry: "./entrypoints/inertia.tsx",
      },
    }),
  ],
}))
