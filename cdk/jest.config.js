module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  testMatch: ['**/*.test.ts'],
  // ts ennen js:aa, jotta testit kohdistuvat lähdekoodiin eivätkä lib-hakemistoon
  // jääneisiin vanhoihin käännöstuloksiin (vrt. ts-node --prefer-ts-exts cdk.json:ssa).
  moduleFileExtensions: ['ts', 'tsx', 'js', 'mjs', 'cjs', 'jsx', 'json', 'node'],
  transform: {
    '^.+\\.tsx?$': 'ts-jest'
  }
};
