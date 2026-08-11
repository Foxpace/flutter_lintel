# Maintainability

[← Bloc and Cubit](bloc-and-cubit.md) · [Rule index](../rules.md)

## `file_line_count`

What it catches: handwritten Dart files over 300 lines by default. Generated
files are ignored.

Bad:

```text
lib/features/library/cubits/library_cubit.dart: 347 lines
```

Good:

```text
lib/features/library/cubits/library_cubit.dart: 180 lines
lib/features/library/use_cases/library_use_cases.dart: 95 lines
lib/features/library/models/library_state.dart: 72 lines
```

Line count is deliberately a dedicated diagnostic so teams can enable or
disable file size independently from class and callable size checks.

## `long_parameter_list`

What it catches: constructors, functions, and methods with more than five
parameters by default. Constructor size is intentionally measured by inputs,
not source lines. Data-class constructors, generated files, and `copyWith`
declarations are ignored. The separate `data_class_uses_freezed` rule governs
whether data-only classes use Freezed.

Bad:

```dart
Future<void> importBook(
  String path,
  String title,
  String author,
  String narrator,
  Duration duration,
  Uint8List? artwork,
) async {}
```

Good:

```dart
@freezed
class ImportBookRequest with _$ImportBookRequest {
  const factory ImportBookRequest({
    required String path,
    required String title,
    required String author,
    required String narrator,
    required Duration duration,
    Uint8List? artwork,
  }) = _ImportBookRequest;
}

Future<void> importBook(ImportBookRequest request) async {}
```

Grouping cohesive inputs into an immutable request or intent makes the
architecture boundary easier to evolve without positional or call-site
ambiguity.

## `maintainability_limits`

What it catches:

| Source unit | Maximum lines |
| --- | ---: |
| Class | 300 |
| Non-`build` method | 30 |
| `build` method | 90 |
| Top-level function | 30 |

Test `main` functions are exempt from the callable limit.

Bad:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  // 400 lines combining loading, filtering, import, navigation, and dialogs.
}
```

Good:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._useCases, this._projector)
      : super(const LibraryState());

  final LibraryUseCases _useCases;
  final LibraryProjector _projector;
}
```

Extract by cohesive responsibility, while keeping mutable feature state in the
Cubit rather than moving it into stateful services.

## `visual_grouping`

What it catches: methods and functions in non-UI production code with more
than 15 consecutive nonblank lines by default. UI,
presentation, theme, navigation, roots, and presenters are excluded.
Flutter `build` methods are also exempt because their size is governed
separately by `maintainability_limits`.

Bad:

```dart
Future<void> importBook() async {
  final selected = await picker.pick();
  if (selected == null) return;
  final metadata = await parser.parse(selected);
  final artwork = await artworkReader.read(selected);
  // More parsing, validation, mapping, copying, and persistence with no
  // visual separation between phases...
}
```

Good:

```dart
Future<void> importBook() async {
  final selected = await picker.pick();
  if (selected == null) return;

  final metadata = await parser.parse(selected);
  final artwork = await artworkReader.read(selected);

  await repository.save(Book.fromImport(selected, metadata, artwork));
}
```

Blank lines should expose cohesive phases. If a phase remains large, extract a
named method or collaborator.

## Configuring numeric limits

All numeric thresholds can be overridden in an optional
`lintel.yaml` at the package or workspace root:

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

The nearest configuration file above the analyzed source wins. Missing,
invalid, and non-positive values use the defaults shown above. Restart the
Dart analysis server after changing the file.

The analyzer's plugin configuration currently accepts only a plugin source
and diagnostic enable/severity values, so numeric settings cannot live inside
the `plugins.lintel` entry in `analysis_options.yaml`.
