# Changelog

## 0.1.3

- Exempt Flutter `build` methods from visual-grouping checks while retaining
  their separate size limit.
- Allow `Map<String, dynamic>` at JSON boundaries while continuing to reject
  other explicit `dynamic` types.
- Exempt data-only class constructors from parameter-count limits.
- Allow tests to omit phases with no code and reject empty phase markers.

## 0.1.2

- Fix the default top-level function limit to 30 lines so it matches the
  non-`build` method limit.
- Add boundary coverage for top-level functions at and above the default
  limit.

## 0.1.1

- Improve automated publishing with main-branch ancestry and release-version
  validation.
- Use short-lived pub.dev OIDC authentication with a deployment environment
  binding and least-privilege GitHub token permissions.
- Pin GitHub Actions dependencies to verified commits.
- Link every GitHub release to its versioned changelog on pub.dev.

## 0.1.0

- Initial release of Lintel.
- Add 41 opt-in analyzer diagnostics covering architecture boundaries,
  Bloc/Cubit usage, correctness, safety, testing, and maintainability.
- Add configurable limits for file, class, callable, test, parameter-list, and
  visual grouping sizes.
- Include complete rule documentation, configuration examples, and diagnostic
  test coverage.
