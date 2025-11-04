const {
    defineConfig,
    globalIgnores,
} = require("eslint/config");

const tsParser = require("@typescript-eslint/parser");
const typescriptEslint = require("@typescript-eslint/eslint-plugin");
const prettier = require("eslint-plugin-prettier");
const _import = require("eslint-plugin-import");
const unusedImports = require("eslint-plugin-unused-imports");

const {
    fixupPluginRules,
} = require("@eslint/compat");

const globals = require("globals");
const js = require("@eslint/js");

const {
    FlatCompat,
} = require("@eslint/eslintrc");

const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

module.exports = defineConfig([{
    languageOptions: {
        parser: tsParser,

        globals: {
            ...globals.node,
        },
    },

    settings: {
        react: {
            version: "detect",
        },
    },

    extends: compat.extends("eslint:recommended", "plugin:@typescript-eslint/recommended", "prettier"),

    plugins: {
        "@typescript-eslint": typescriptEslint,
        prettier,
        import: fixupPluginRules(_import),
        "unused-imports": unusedImports,
    },

    rules: {
        "@typescript-eslint/no-empty-function": "off",
        "@typescript-eslint/no-explicit-any": "off",
        "@typescript-eslint/no-inferrable-types": "off",
        "@typescript-eslint/no-non-null-assertion": "off",
        "@typescript-eslint/no-shadow": "error",

        "@typescript-eslint/ban-types": ["error", {
            types: {
                object: false,
            },

            extendDefaults: true,
        }],

        "@typescript-eslint/array-type": ["error", {
            default: "generic",
        }],

        "prettier/prettier": ["warn", {
            usePrettierrc: true,
        }],

        "import/no-default-export": "error",
        "import/no-duplicates": "error",
        "import/no-anonymous-default-export": "off",

        "import/order": ["error", {
            groups: ["builtin", "external", "internal"],

            pathGroups: [{
                pattern: "#/**",
                group: "internal",
                position: "before",
            }],

            "newlines-between": "always",

            alphabetize: {
                order: "asc",
                caseInsensitive: true,
            },
        }],

        "no-negated-condition": "error",
        "no-implicit-coercion": "error",
        "no-var": "error",
        "no-unused-vars": "off",
        "@typescript-eslint/no-unused-vars": ["off"],
        "unused-imports/no-unused-imports": "error",
    },
}, {
    files: ["**/*.config.ts"],

    rules: {
        "import/no-default-export": "off",
    },
}, globalIgnores(["**/node_modules/", "**/*.js", "**/*.d.ts"])]);
