# Testing, errors, and correctness

[← Dependency direction and data](dependency-direction-and-data.md) · [Rule index](../rules.md) · [Next: Bloc and Cubit →](bloc-and-cubit.md)

## `completer_errors_need_stack_trace`

What it catches: a `completeError` invocation with exactly one argument.

Bad:

```dart
completer.completeError(error);
```

Good:

```dart
completer.completeError(error, stackTrace);
```

Without the second argument, asynchronous diagnostics lose the original error
location.

## `no_assignments_in_conditions`

What it catches: assignment expressions inside `if`, `while`, and `do`
conditions.

Bad:

```dart
if (isReady = await repository.isReady()) {
  start();
}
```

Good:

```dart
isReady = await repository.isReady();
if (isReady) {
  start();
}
```

Separating mutation from branching makes intent clear and avoids accidental
assignment where a comparison was intended.

## `no_compatibility_shims`

What it catches:

- `@Deprecated` declarations;
- `noSuchMethod` overrides in tests.

Bad:

```dart
@Deprecated('Use LibraryUseCases')
class LegacyLibraryService {}
```

Good:

```dart
abstract interface class RefreshLibrary {
  Future<void> run();
}

class RefreshLibraryUseCase implements RefreshLibrary {
  const RefreshLibraryUseCase(this._repository);

  final BookRepository _repository;

  @override
  Future<void> run() => _repository.refresh();
}
```

The rule favors current contracts and complete test fakes over long-lived
compatibility APIs. Mixin declarations and `part`/`part of` directives are
allowed; they are ordinary Dart language features.

## `no_dynamic`

What it catches: every explicit `dynamic` type annotation in handwritten Dart,
including parameters, return types, variables, records, and generic arguments.

Bad:

```dart
Object? readValue(Map<String, dynamic> json) => json['value'];
```

Good:

```dart
Object? readValue(Map<String, Object?> json) => json['value'];
```

At application boundaries, validate `Object?` values and convert them into
typed models before passing them into use cases or Cubits.

## `no_empty_test_groups`

What it catches: a `group` callback without a nested `test` or `testWidgets`
invocation.

Bad:

```dart
group('Given an empty library', () {});
```

Good:

```dart
group('Given an empty library', () {
  test('Then the empty state is shown', () {});
});
```

Empty groups can make an unfinished behavior scenario look covered.

## `no_enum_values_by_index`

What it catches: enum value access through `EnumType.values[index]`.

Bad:

```dart
final format = BookFormat.values[storedIndex];
```

Good:

```dart
final format = BookFormat.values.byName(storedName);
```

Persisted indexes become invalid when enum cases are inserted or reordered;
stable names or explicit mappings preserve compatibility.

## `no_global_mutable_state`

What it catches: non-final, non-const top-level variables in handwritten
`lib/` files.

Bad:

```dart
var activeBookId = '';
```

Good:

```dart
const defaultBookId = '';
```

Runtime state should belong to a Cubit or another explicitly injected owner,
not a hidden global variable.

## `no_non_null_assertions`

What it catches: every postfix `!` in handwritten Dart under `lib/`, `test/`,
or `tool/`.

Bad:

```dart
final book = state.selectedBook!;
```

Good:

```dart
final book = state.selectedBook;
if (book == null) return;
```

Pattern matching is also encouraged when it makes the branch clearer:

```dart
if (state.selectedBook case final book?) {
  onIntent(LibraryIntent.open(book));
}
```

## `no_one_field_records`

What it catches: record literals containing exactly one field.

Bad:

```dart
final result = (book,);
```

Good:

```dart
final result = book;
```

Use a named value type when the wrapper carries domain meaning.

## `no_public_test_members`

What it catches: public top-level functions, variables, classes, mixins,
enums, extensions, extension types, and type aliases in test files. The
`main` entry point remains allowed.

Bad:

```dart
Book createBook() => const Book();
```

Good:

```dart
Book _createBook() => const Book();
```

Move helpers intended for production reuse into `lib/` instead of exporting
them accidentally from a test library.

## `no_self_assignment`

What it catches: a simple assignment whose left and right expressions are
identical.

Bad:

```dart
selectedBook = selectedBook;
```

Good:

```dart
selectedBook = requestedBook;
```

Self-assignment has no effect and usually indicates that the wrong source
variable was selected.

## `no_self_comparison`

What it catches: equality or ordering comparisons with identical operands.

Bad:

```dart
if (bookId == bookId) {}
```

Good:

```dart
if (bookId == selectedBookId) {}
```

These comparisons produce a constant result and commonly hide a naming typo.

## `prefer_contains_key`

What it catches: `map.keys.contains(key)`.

Bad:

```dart
if (booksById.keys.contains(bookId)) {}
```

Good:

```dart
if (booksById.containsKey(bookId)) {}
```

`containsKey` states the operation directly and uses the map’s key lookup.

## `single_operation_try_blocks`

What it catches: a `try` body or `catch` body under `lib/` with more than one
top-level statement. Nested detail inside one delegated call is not counted.

Bad:

```dart
try {
  final books = await repository.loadBooks();
  emit(state.copyWith(books: books));
} catch (_) {
  logger.warning('Loading failed');
  emit(state.copyWith(status: LoadStatus.failure));
}
```

Good:

```dart
try {
  await _loadBooksAndEmit();
} catch (_) {
  _emitLoadFailure();
}
```

This keeps the error boundary readable and gives the successful and failed
operations explicit names.

## `test_body_uses_given_when_then_comments`

What it catches: nonempty `test`, `testWidgets`, and reflective `test_*` bodies
without ordered `// GIVEN`, `// WHEN`, and `// THEN` phase comments.

Bad:

```dart
test('Given a book, When opened, Then it is selected', () {
  final book = Book();
  controller.open(book);
  expect(controller.selected, book);
});
```

Good:

```dart
test('Given a book, When opened, Then it is selected', () {
  // GIVEN
  final book = Book();
  // WHEN
  controller.open(book);
  // THEN
  expect(controller.selected, book);
});
```

Empty test callbacks are exempt because no phases are present to label.

## `test_descriptions_use_given_when_then`

What it catches: `test`, `testWidgets`, and reflective `test_*` descriptions
that do not state Given, When, and Then in that order.

Bad:

```dart
test('loads books', () {});
```

Good:

```dart
test('Given stored books, When refreshed, Then the books are emitted', () {});
```

Reflective test names use the equivalent
`test_given..._when..._then...` structure.

## `test_groups_describe_intention`

What it catches: `group` and named `defineReflectiveSuite` descriptions that
are empty or begin with Given, When, or Then.

Bad:

```dart
group('Given stored books', () {});
```

Good:

```dart
group('Library refresh behavior', () {});
```

The rule can reject scenario-phase names, but it cannot infer whether an
arbitrary label expresses a useful shared intention.

## `test_line_count`

What it catches: `test`, `testWidgets`, and reflective `test_*` declarations
over 25 lines by default.

Bad:

```dart
test('Given a library, When imported, Then all books are stored', () {
  // More than 25 lines of fixture setup, execution, and assertions.
});
```

Good:

```dart
test('Given a library, When imported, Then all books are stored', () {
  // GIVEN
  final fixture = libraryFixture();
  // WHEN
  final result = importer.import(fixture);
  // THEN
  expect(result, expectedLibrary());
});
```

Extracting fixture builders keeps the scenario focused without hiding its
Given/When/Then behavior. Override the limit with `test_lines`.
