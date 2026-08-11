# Lintel

**Architecture rules that fail where developers can fix them: in the editor.**

`lintel` is an analyzer plugin for Flutter projects that turns
architecture decisions into diagnostics. It guards feature boundaries,
dependency direction, Bloc and Cubit usage, immutable state, maintainability,
correctness, and testing conventions.

> [!IMPORTANT]
> This package is intentionally opinionated. It does not try to accommodate
> every Flutter architecture. It favors feature-first organization,
> unidirectional state flow, explicit composition roots, use-case boundaries,
> immutable data, small source units, and behavior-oriented tests.

If those constraints match the codebase you want, the package makes them
automatic. If they do not, enable only the diagnostics that support your
architecture.

## Why it exists

Architecture usually begins as a diagram and slowly becomes a suggestion.
Code review then has to catch misplaced repositories, UI-owned business logic,
state holders depending on each other, mutable globals, oversized files, and
tests that describe implementation instead of behavior.

Standard Dart and Flutter lints are excellent at language and framework
correctness, but they do not know the boundaries of your application.
`lintel` fills that gap with diagnostics for decisions such as:

- widgets render state and dispatch intents;
- Bloc and Cubit classes own state without depending on other state holders;
- application logic lives behind explicit application or domain contracts;
- composition roots wire dependencies instead of performing business work;
- feature folders have predictable ownership and layout;
- handwritten files, declarations, and callables stay focused;
- test groups describe a shared intention, while each test uses Given/When/Then
  in its description and body phases;
- unsafe shortcuts such as explicit `dynamic` and non-null assertions are
  rejected.

## What it catches

### Keep state management out of widgets

Bad:

```dart
class BookTile extends StatelessWidget {
  const BookTile({required this.cubit, required this.book, super.key});

  final LibraryCubit cubit;
  final Book book;

  @override
  Widget build(BuildContext context) {
    return ListTile(onTap: () => cubit.openBook(book));
  }
}
```

Good:

```dart
class BookTile extends StatelessWidget {
  const BookTile({required this.onOpen, required this.book, super.key});

  final VoidCallback onOpen;
  final Book book;

  @override
  Widget build(BuildContext context) {
    return ListTile(onTap: onOpen);
  }
}
```

The composition root translates `onOpen` into an application intent. The
widget remains reusable and unaware of state-management infrastructure.

### Keep state holders independent

Bad:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._playerCubit);

  final PlayerCubit _playerCubit;
}
```

Good:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._useCases);

  final LibraryUseCases _useCases;
}
```

Cross-feature coordination belongs in a composition root. Shared behavior
belongs behind an explicit application or domain contract.

### Make boundaries statically typed

Bad:

```dart
Object? readValue(Map<String, dynamic> json) => json['value'];
```

Good:

```dart
Object? readValue(Map<String, Object?> json) => json['value'];
```

Validate boundary values and convert them into typed models before they reach
use cases or state holders.

### Keep error handling focused

Bad:

```dart
try {
  final book = await repository.load();
  emit(state.copyWith(book: book));
  analytics.trackBookOpened(book.id);
} catch (error, stackTrace) {
  logger.error(error, stackTrace);
  emit(state.copyWith(hasError: true));
}
```

Good:

```dart
try {
  await _loadBook();
} catch (error, stackTrace) {
  _handleLoadFailure(error, stackTrace);
}
```

Focused error boundaries expose the intent of both the successful operation
and its recovery path.

## Architecture contract

The full profile guides projects toward these boundaries:

- Each `lib/features/<feature>` owns `cubits`, `models`, `repos`, `use_cases`,
  `ui`, `ui/widgets`, and one `*_root.dart` composition file.
- A feature composition root provides exactly one Cubit and only wires
  dependencies, state, and intents.
- Widgets do not resolve Cubits, navigate, access adapters or platform APIs,
  perform feature I/O, or subscribe to Bloc state directly.
- A Cubit constructor-injects its application or domain collaborators, may use
  one optional `UseCases` umbrella, keeps mutable feature data in immutable
  state, and does not construct those collaborators itself.
- Bloc and Cubit fields are private, state types end in `State`, emitted state
  instances are new, and state holders do not depend on each other.
- Application and domain code depend on contracts. Data adapters and platform
  packages remain outside presentation.
- Data-only values use Freezed. Files, declarations, parameter lists,
  callables, and error boundaries remain deliberately small.
- Blocs and Cubits may use mixins for cross-cutting concerns such as logging,
  metrics, and tracing. Feature-specific behavior remains in the state holder
  or an injected collaborator; that semantic distinction is left to review.

Generated files such as `*.g.dart`, `*.freezed.dart`, `*.config.dart`, and
`*.gr.dart` are excluded from rules that target handwritten source.

## Installation

The package uses Dart's analyzer-plugin system and requires Dart 3.12.2 or
later. Enable it in the root `analysis_options.yaml` of the consuming package
or workspace:

```yaml
plugins:
  lintel:
    version: ^0.1.0
    diagnostics:
      cubit_state_ownership: true
      dependency_direction: true
      feature_layout: true
      file_line_count: true
      no_bloc_to_bloc_dependencies: true
      no_dynamic: true
      no_non_null_assertions: true
      widget_dispatches_intents_only: true

analyzer:
  exclude:
    - lib/**.freezed.dart
    - lib/**.g.dart
```

For local plugin development, replace `version` with an absolute or workspace
path:

```yaml
plugins:
  lintel:
    path: /absolute/path/to/lintel
```

Restart the Dart analysis server after adding or changing the plugin.

Diagnostics are opt-in, so a team can start with a focused subset and add
stricter architecture rules over time.
Diagnostic IDs are concise because they are already scoped by the
`lintel` plugin key; for example, use `feature_layout` rather than
`flutter_arch_feature_layout`.

### Numeric limits

The default maintainability profile limits files and classes to 300 lines,
non-build methods and top-level functions to 30 lines, Flutter `build` methods
to 90 lines, tests to 25 lines, and uninterrupted non-UI callable phases to 15
nonblank lines. Function and parameter limits are configurable too.
Constructors are limited by parameter count rather than line count.

Create an optional `lintel.yaml` at the package or workspace root
to override any numeric threshold:

```yaml
limits:
  file_lines: 300
  class_lines: 300
  behavior_method_lines: 30
  build_method_lines: 90
  function_lines: 30
  consecutive_nonblank_lines: 15
  parameters: 5
  test_lines: 25
```

See the [maintainability rule documentation](doc/rules/maintainability.md)
for scope and fallback behavior. Restart the Dart analysis server after
changing the limits file.

<details>
<summary>Complete configuration for all 41 diagnostics</summary>

```yaml
plugins:
  lintel:
    version: ^0.1.0
    diagnostics:
      bloc_fields_must_be_private: true
      bloc_state_must_use_state_suffix: true
      completer_errors_need_stack_trace: true
      composition_root_responsibility: true
      cubit_state_ownership: true
      cubit_uses_one_use_case_umbrella: true
      data_class_uses_freezed: true
      dependency_direction: true
      emit_new_state_instances: true
      feature_layout: true
      file_line_count: true
      long_parameter_list: true
      maintainability_limits: true
      no_assignments_in_conditions: true
      no_bloc_to_bloc_dependencies: true
      no_build_context_in_bloc: true
      no_compatibility_shims: true
      no_dynamic: true
      no_empty_test_groups: true
      no_enum_values_by_index: true
      no_global_mutable_state: true
      no_non_null_assertions: true
      no_one_field_records: true
      no_public_test_members: true
      no_self_assignment: true
      no_self_comparison: true
      no_widget_returning_helpers: true
      prefer_contains_key: true
      repository_ownership: true
      single_cubit_composition_root: true
      single_operation_try_blocks: true
      single_public_declaration_per_file: true
      stateless_application_service: true
      test_body_uses_given_when_then_comments: true
      test_descriptions_use_given_when_then: true
      test_groups_describe_intention: true
      test_line_count: true
      use_case_umbrella: true
      visual_grouping: true
      widget_dispatches_intents_only: true
      widget_file_cohesion: true
```

</details>

## Choosing the profile

This package makes trade-offs on purpose:

- It optimizes for predictable ownership over maximum flexibility.
- It treats Cubit intent methods as a valid public API but rejects public
  state-holder fields.
- It allows Bloc and Cubit mixins for cross-cutting concerns; deciding whether
  a mixin contains feature-specific logic remains an architectural review.
- It prefers typed boundary parsing over `dynamic`.
- It favors one public declaration per file and a 300-line handwritten file
  limit.
- It expects Freezed for data-only values.
- It groups tests by intention and expects each test to communicate Given,
  When, and Then explicitly in no more than 25 lines by default.

Adopt the whole profile when those constraints are desirable. Otherwise,
select the diagnostics that represent your team's decisions. An opinionated
tool is useful only when its opinions are visible.

## Rule reference

The [rule guide index](doc/rules.md) links to category-focused documentation
for every diagnostic, including:

- the exact pattern it reports;
- a bad example;
- a preferred alternative;
- relevant exclusions and scope.

## Contributing

Run the package checks before submitting a change:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

Group tests by intention. Test descriptions should contain Given, When, and
Then; nonempty bodies should mark the same phases with comments. Keep each test
at 25 lines or fewer and include both reporting and allowed cases for every new
diagnostic.

## License

Licensed under the [MIT License](LICENSE).
