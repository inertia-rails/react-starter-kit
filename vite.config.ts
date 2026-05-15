import inertia from "@inertiajs/vite"
import babel from "@rolldown/plugin-babel"
import tailwindcss from "@tailwindcss/vite"
import react, { reactCompilerPreset } from "@vitejs/plugin-react"
import { defineConfig } from "vite"
import RubyPlugin from "vite-plugin-ruby"

export default defineConfig(({ command }) => ({
  ssr: {
    // Prebuild ssr.js so we can drop node_modules from the container.
    noExternal: command === "build" ? true : undefined,
    // React 19 ships CJS-only — externalize in dev so Node handles require natively.
    external:
      command === "serve"
        ? ["react", "react-dom", "react/jsx-runtime", "react/jsx-dev-runtime"]
        : undefined,
  },
  plugins: [
    react(),
    babel({ presets: [reactCompilerPreset()] }),
    tailwindcss(),
    RubyPlugin(),
    inertia({ ssr: "./entrypoints/inertia.tsx" }),
  ],
}))
