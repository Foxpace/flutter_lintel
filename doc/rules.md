# Flutter architecture rule guide

This guide describes every diagnostic registered by `flutter_arch_guard`.
“Bad” examples produce the named diagnostic; “good” examples show the intended
direction. Generated files (`*.g.dart`, `*.freezed.dart`, `*.config.dart`, and
`*.gr.dart`) are ignored where a rule targets handwritten source.

The maintainability rules are selected for their fit with this Flutter
architecture profile and use package-specific diagnostics.

## Categories

- [Structure and ownership](rules/structure-and-ownership.md)
- [State, intents, and application behavior](rules/state-intents-and-application.md)
- [Dependency direction and data](rules/dependency-direction-and-data.md)
- [Testing, errors, and correctness](rules/testing-errors-and-correctness.md)
- [Bloc and Cubit](rules/bloc-and-cubit.md)
- [Maintainability](rules/maintainability.md)

## Rule summary

| Diagnostic | What it catches |
| --- | --- |
| [`bloc_fields_must_be_private`](rules/bloc-and-cubit.md#bloc_fields_must_be_private) | Public instance fields declared by a Bloc or Cubit. |
| [`bloc_state_must_use_state_suffix`](rules/bloc-and-cubit.md#bloc_state_must_use_state_suffix) | Bloc or Cubit state types without a `State` suffix. |
| [`completer_errors_need_stack_trace`](rules/testing-errors-and-correctness.md#completer_errors_need_stack_trace) | `completeError` calls without a stack trace argument. |
| [`composition_root_responsibility`](rules/state-intents-and-application.md#composition_root_responsibility) | State, business work, or adapters owned by a `*_root.dart` file. |
| [`cubit_state_ownership`](rules/state-intents-and-application.md#cubit_state_ownership) | Ordinary mutable fields retained by a Cubit. |
| [`cubit_uses_one_use_case_umbrella`](rules/state-intents-and-application.md#cubit_uses_one_use_case_umbrella) | Cubits with multiple `*UseCases` dependencies or locally constructed application collaborators. |
| [`data_class_uses_freezed`](rules/dependency-direction-and-data.md#data_class_uses_freezed) | Data-only classes that do not use `@freezed`. |
| [`dependency_direction`](rules/dependency-direction-and-data.md#dependency_direction) | Imports that cross architecture layers in the wrong direction, plus raw platform channels. |
| [`emit_new_state_instances`](rules/bloc-and-cubit.md#emit_new_state_instances) | `emit(state)` calls that reuse the current state instance. |
| [`feature_layout`](rules/structure-and-ownership.md#feature_layout) | Feature folders that do not expose the standard feature structure and a composition root. |
| [`file_line_count`](rules/maintainability.md#file_line_count) | Handwritten Dart files beyond the configured project limit. |
| [`long_parameter_list`](rules/maintainability.md#long_parameter_list) | Constructors and callables with more than five parameters. |
| [`maintainability_limits`](rules/maintainability.md#maintainability_limits) | Oversized classes, methods, or functions. |
| [`no_assignments_in_conditions`](rules/testing-errors-and-correctness.md#no_assignments_in_conditions) | Assignment expressions embedded in `if`, `while`, or `do` conditions. |
| [`no_bloc_to_bloc_dependencies`](rules/bloc-and-cubit.md#no_bloc_to_bloc_dependencies) | Bloc or Cubit fields whose type is another state holder. |
| [`no_build_context_in_bloc`](rules/bloc-and-cubit.md#no_build_context_in_bloc) | `BuildContext` types inside Blocs, Cubits, or event classes. |
| [`no_compatibility_shims`](rules/testing-errors-and-correctness.md#no_compatibility_shims) | Deprecated APIs and incomplete test fakes. |
| [`no_dynamic`](rules/testing-errors-and-correctness.md#no_dynamic) | Explicit `dynamic` types in handwritten Dart code. |
| [`no_empty_test_groups`](rules/testing-errors-and-correctness.md#no_empty_test_groups) | Test groups that contain no `test` or `testWidgets` invocation. |
| [`no_enum_values_by_index`](rules/testing-errors-and-correctness.md#no_enum_values_by_index) | Enum values selected by unstable positional index. |
| [`no_global_mutable_state`](rules/testing-errors-and-correctness.md#no_global_mutable_state) | Mutable top-level variables in handwritten library code. |
| [`no_non_null_assertions`](rules/testing-errors-and-correctness.md#no_non_null_assertions) | Postfix non-null assertions (`!`) in handwritten Dart. |
| [`no_one_field_records`](rules/testing-errors-and-correctness.md#no_one_field_records) | Record literals that wrap only one value. |
| [`no_public_test_members`](rules/testing-errors-and-correctness.md#no_public_test_members) | Public test-only functions, variables, and types. |
| [`no_self_assignment`](rules/testing-errors-and-correctness.md#no_self_assignment) | Assignments whose source and target are identical. |
| [`no_self_comparison`](rules/testing-errors-and-correctness.md#no_self_comparison) | Comparisons whose left and right operands are identical. |
| [`no_widget_returning_helpers`](rules/structure-and-ownership.md#no_widget_returning_helpers) | Functions and non-build methods returning `Widget`. |
| [`prefer_contains_key`](rules/testing-errors-and-correctness.md#prefer_contains_key) | Indirect map lookups using `map.keys.contains(key)`. |
| [`repository_ownership`](rules/structure-and-ownership.md#repository_ownership) | `*Repository` declarations outside `repos/`. |
| [`single_cubit_composition_root`](rules/structure-and-ownership.md#single_cubit_composition_root) | Feature roots that provide zero or multiple Cubit types. |
| [`single_operation_try_blocks`](rules/testing-errors-and-correctness.md#single_operation_try_blocks) | `try` or `catch` blocks containing multiple top-level operations. |
| [`single_public_declaration_per_file`](rules/structure-and-ownership.md#single_public_declaration_per_file) | Multiple public type declarations in one handwritten file. |
| [`stateless_application_service`](rules/state-intents-and-application.md#stateless_application_service) | Mutable fields retained by application services in `use_cases/`. |
| [`test_body_uses_given_when_then_comments`](rules/testing-errors-and-correctness.md#test_body_uses_given_when_then_comments) | Nonempty tests without ordered Given/When/Then phase comments. |
| [`test_descriptions_use_given_when_then`](rules/testing-errors-and-correctness.md#test_descriptions_use_given_when_then) | Tests whose descriptions do not state Given, When, and Then in order. |
| [`test_groups_describe_intention`](rules/testing-errors-and-correctness.md#test_groups_describe_intention) | Test groups named after scenario phases instead of a shared intention. |
| [`test_line_count`](rules/testing-errors-and-correctness.md#test_line_count) | Tests beyond the configured line limit. |
| [`use_case_umbrella`](rules/state-intents-and-application.md#use_case_umbrella) | Public raw collaborators exposed by a `*UseCases` umbrella. |
| [`visual_grouping`](rules/maintainability.md#visual_grouping) | Non-UI callables above the configured consecutive-nonblank-line limit. |
| [`widget_dispatches_intents_only`](rules/state-intents-and-application.md#widget_dispatches_intents_only) | UI code coupled directly to Cubits, routing, DI, filesystem, or Bloc subscriptions. |
| [`widget_file_cohesion`](rules/structure-and-ownership.md#widget_file_cohesion) | Multiple public widgets in one file or a widget/file-name mismatch. |
