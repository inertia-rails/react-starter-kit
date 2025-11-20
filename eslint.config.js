import pluginJs from "@eslint/js"
import prettierConfig from "eslint-config-prettier/flat"
import importPlugin from "eslint-plugin-import"
import pluginReact from "eslint-plugin-react"
import reactHooks from "eslint-plugin-react-hooks"
import globals from "globals"
import tseslint from "typescript-eslint"

/** @type {import('eslint').Linter.Config[]} */
export default [
  { files: ["app/frontend/**/*.{js,mjs,cjs,ts,jsx,tsx}"] },
  { ignores: ["app/frontend/routes/*"] },
  {
    settings: {
      react: {
        version: "detect",
      },
    },
    languageOptions: {
      globals: { ...globals.browser, ...globals.node },
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  pluginJs.configs.recommended,
  reactHooks.configs.flat.recommended,
  ...tseslint.configs.stylisticTypeChecked,
  ...tseslint.configs.recommendedTypeChecked,
  pluginReact.configs.flat.recommended,
  pluginReact.configs.flat["jsx-runtime"],
  prettierConfig,
  {
    ...importPlugin.flatConfigs.recommended,
    ...importPlugin.flatConfigs.typescript,
    ...importPlugin.flatConfigs.react,
    settings: { "import/resolver": { typescript: {} } },
    rules: {
      "import/order": [
        "error",
        {
          pathGroups: [
            {
              pattern: "@/**",
              group: "external",
              position: "after",
            },
          ],
          "newlines-between": "always",
          named: true,
          alphabetize: { order: "asc" },
        },
      ],
      "import/first": "error",
      "import/extensions": [
        "error",
        "always",
        {
          js: "never",
          jsx: "never",
          ts: "never",
          tsx: "never",
        },
      ],
      "@typescript-eslint/consistent-type-imports": "error",
    },
  },
  {
    files: ["**/*.js"],
    ...tseslint.configs.disableTypeChecked,
  },
]
