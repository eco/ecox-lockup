module.exports = {
  extends: ['eslint:recommended', 'plugin:@typescript-eslint/recommended', "plugin:node/recommended",],
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint'],
  root: true,
  rules: {
    "no-unused-expressions": 0,
    "eol-last": ["error", "always"],
    "no-plusplus": 0,
    "prefer-destructuring": 0,
    "no-multiple-empty-lines": ["error", {
      max: 1,
      maxEOF: 0,
      maxBOF: 0
    }],
    "node/no-unsupported-features/es-syntax": [
      "error",
      { ignores: ["modules"] },
    ],
    "node/no-missing-import": [
      "error",
      {
        allowModules: [],
        tryExtensions: [".js", ".json", ".node", ".ts", ".d.ts"],
      },
    ],
    "node/no-missing-require": [
      "error", {
        allowModules: [],
        tryExtensions: [".js", ".json", ".node", ".ts", ".d.ts"]
      }]
  },
};