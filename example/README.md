# Lintel example

Enable the plugin and the diagnostics that represent your architecture in the
root `analysis_options.yaml`:

```yaml
plugins:
  lintel:
    version: ^0.1.0
    diagnostics:
      cubit_state_ownership: true
      dependency_direction: true
      file_line_count: true
      maintainability_limits: true
      no_bloc_to_bloc_dependencies: true
      visual_grouping: true
```

The diagnostics appear in the editor and in `dart analyze`. For example, this
Cubit-owned mutable value is reported:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState());

  int selectedIndex = 0;
}
```

Keep mutable feature data in immutable state instead:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState());

  void selectBook(int index) {
    emit(state.copyWith(selectedIndex: index));
  }
}
```

Numeric thresholds have built-in defaults. To customize them, add an optional
`lintel.yaml` next to `analysis_options.yaml`:

```yaml
limits:
  file_lines: 300
  class_lines: 300
  behavior_method_lines: 30
  build_method_lines: 90
  consecutive_nonblank_lines: 15
  parameters: 5
  test_lines: 25
```

See the [complete rule index](../doc/rules.md) for every diagnostic, its scope,
and good and bad examples.
