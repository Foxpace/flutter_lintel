# Dependency direction and data

[← State, intents, and application](state-intents-and-application.md) · [Rule index](../rules.md) · [Next: Testing, errors, and correctness →](testing-errors-and-correctness.md)

## `data_class_uses_freezed`

What it catches: a class with instance fields or constructor data, no
non-getter methods, and no `@freezed` annotation. `*UseCases` umbrellas are
excluded because they are collaborator bundles, not value objects.

Bad:

```dart
class Book {
  const Book(this.id, this.title);

  final String id;
  final String title;
}
```

Good:

```dart
@freezed
class Book with _$Book {
  const factory Book({
    required String id,
    required String title,
  }) = _Book;
}
```

Freezed makes immutability, equality, copying, and exhaustive state modeling
consistent across application state and domain values.
## `dependency_direction`

What it catches:

- presentation importing data implementations;
- cross-feature presentation imports outside a composition root;
- data adapters importing presentation;
- presentation importing known platform packages such as `just_audio`,
  `file_picker`, or `path_provider`;
- presentation accessing core DI outside a root;
- domain importing data, presentation, or Flutter;
- application/use-case code importing implementations, Cubits, UI, or Flutter;
- UI importing repositories or use cases;
- non-composition core code importing features;
- handwritten `MethodChannel`, `BasicMessageChannel`, or `EventChannel`
  construction.

Bad — a UI file imports an adapter:

```dart
import '../repos/implementations/sembast_book_repository.dart';

class LibraryScreen extends StatelessWidget {
  final repository = SembastBookRepository();
}
```

Good — dependencies point toward a contract:

```dart
// repos/book_repository.dart
abstract interface class BookRepository {
  Future<List<Book>> loadBooks();
}

// use_cases/load_library_use_case.dart
class LoadLibraryUseCase {
  const LoadLibraryUseCase(this._repository);

  final BookRepository _repository;

  Future<List<Book>> run() => _repository.loadBooks();
}
```

The concrete adapter is bound to `BookRepository` in DI/composition code.

