module.exports = {
  env: {
    browser: true,
    es2021: true,
  },
  extends: ['standard-with-typescript', 'prettier'],
  overrides: [],
  parserOptions: {
    ecmaVersion: 'latest',
  },
  rules: {
    'no-var': 0,
    eqeqeq: 0,
    'no-fallthrough': 0,
    'no-redeclare': 0,
    'n/no-callback-literal': 0,
    'no-caller': 0,
    'no-extend-native': 0,
    'no-useless-escape': 0,
    'no-unused-expressions': 0,
    camelcase: 0,
    'no-eval': 0,
    'no-unused-vars': 0,
    'no-new': 0,
    'no-undef': 0,
  },
};
