# Structure and ownership

[← Rule index](../rules.md) · [Next: State, intents, and application →](state-intents-and-application.md)

## `feature_layout`

What it catches: every directory directly below `lib/features/` must contain
`cubits/`, `models/`, `repos/`, `use_cases/`, `ui/`, `ui/widgets/`, and one
top-level file ending in `_root.dart`. The diagnostic is attached to the first
handwritten Dart file in an incomplete feature.

Bad:

```text
lib/features/library/
├── library_page.dart
└── repository.dart
```

Good:

```text
lib/features/library/
├── cubits/
├── models/
├── repos/
├── use_cases/
├── ui/
│   └── widgets/
└── library_root.dart
```

The rule makes feature ownership visible from the directory tree and gives
every feature the same predictable architecture entry points.

## `no_widget_returning_helpers`

What it catches: top-level functions returning `Widget` and non-`build`
methods returning `Widget` in handwritten `lib/` code. Overridden `build`
methods remain valid.

Bad:

```dart
class LibraryScreen extends StatelessWidget {
  Widget _buildHeader() => const Text('Library');

  @override
  Widget build(BuildContext context) => Column(
    children: [_buildHeader()],
  );
}
```

Good:

```dart
class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader();

  @override
  Widget build(BuildContext context) => const Text('Library');
}

class LibraryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Column(
    children: [_LibraryHeader()],
  );
}
```

Widget classes give extracted subtrees identity, focused rebuild boundaries,
and a natural place for their inputs.
## `repository_ownership`

What it catches: a class whose name ends in `Repository` when its file is not
inside a `repos/` directory. Contracts and implementations are both owned by
the repository boundary.

Bad — `lib/features/library/models/book_repository.dart`:

```dart
abstract class BookRepository {
  Future<List<Book>> loadBooks();
}
```

Good — `lib/features/library/repos/book_repository.dart`:

```dart
abstract class BookRepository {
  Future<List<Book>> loadBooks();
}
```

## `single_cubit_composition_root`

What it catches: a `*_root.dart` file that does not contain exactly one unique
`BlocProvider<SomethingCubit>` type.

Bad:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<LibraryCubit>(create: (_) => getIt()),
    BlocProvider<FilterCubit>(create: (_) => getIt()),
  ],
  child: const LibraryScreen(),
);
```

Good:

```dart
BlocProvider<LibraryCubit>(
  create: (_) => getIt<LibraryCubit>()..load(),
  child: const LibraryScreen(),
);
```

One feature Cubit gives the screen one state stream and one intent boundary.
Smaller state concerns can remain immutable values inside that state.

## `single_public_declaration_per_file`

What it catches: a second public class, mixin, enum, extension, or extension
type in the same handwritten Dart file. Private declarations are allowed so a
widget can keep small private implementation details nearby.

Bad:

```dart
class LibraryRequest {}
class LibraryResponse {}
```

Good — `library_request.dart`:

```dart
class LibraryRequest {}
```

And `library_response.dart`:

```dart
class LibraryResponse {}
```

This makes ownership, imports, and file discovery predictable. It does not
prohibit mixins; it only asks each public type to have an explicit home.

## `widget_file_cohesion`

What it catches: more than one public `StatelessWidget` or `StatefulWidget` in
a handwritten file. A `StatefulWidget` and its private `State` implementation
form one cohesive widget and may live in the same file.

Bad — `library.dart`:

```dart
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
}

class BookTile extends StatelessWidget {
  const BookTile({super.key});
}
```


Good — `library_screen.dart`:

```dart
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});
}
```

And `book_tile.dart`:

```dart
class BookTile extends StatelessWidget {
  const BookTile({super.key});
}
```
