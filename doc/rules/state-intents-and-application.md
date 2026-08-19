# State, intents, and application behavior

[← Structure and ownership](structure-and-ownership.md) · [Rule index](../rules.md) · [Next: Dependency direction and data →](dependency-direction-and-data.md)

## `composition_root_responsibility`

What it catches in `*_root.dart` files:

- calls to `setState` or `emit`;
- imports from `repos/implementations/`;
- owned `final` values typed as a repository, use case, workflow, coordinator,
  or service.

Bad:

```dart
class LibraryRootState extends State<LibraryRoot> {
  final SyncService service = SyncService();

  void refresh() {
    setState(() {});
  }
}
```

Good:

```dart
class LibraryRoot extends StatelessWidget {
  const LibraryRoot({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<LibraryCubit>(
    create: (_) => getIt<LibraryCubit>(),
    child: BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) => LibraryScreen(
        state: state,
        onIntent: context.read<LibraryCubit>().onIntent,
      ),
    ),
  );
}
```

The root is the allowed framework-aware adapter around a framework-independent
leaf UI.
## `cubit_state_ownership`

What it catches: non-final, non-const instance fields in a class extending
`Cubit<T>` in a `*_cubit.dart` file. Lifecycle handles (`Timer?` and
`StreamSubscription...`) and explicitly named `*State` or `*Runtime` holders
are allowed.

Bad:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState());

  int selectedIndex = 0;
  List<Book> cachedBooks = [];
}
```

Good:

```dart
@freezed
class LibraryState with _$LibraryState {
  const factory LibraryState({
    @Default(0) int selectedIndex,
    @Default(<Book>[]) List<Book> books,
  }) = _LibraryState;
}

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState());

  void onBookSelected(int index) {
    emit(state.copyWith(selectedIndex: index));
  }
}
```

## `cubit_uses_one_use_case_umbrella`

What it catches in `*_cubit.dart` files:

- a Cubit with more than one non-static field type ending in `UseCases`;
- a Cubit constructing a repository, use case, use-case umbrella, workflow,
  coordinator, or service instead of receiving it as a dependency.

Despite its historical diagnostic name, this rule does not require a
`*UseCases` dependency. A Cubit may directly inject application and domain
contracts such as repositories, services, coordinators, and workflows.

Bad:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(const LibraryState());

  final SyncService _syncService = SyncService();
}
```

Good:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repository, this._syncService)
      : super(const LibraryState());

  final BookRepository _repository;
  final SyncService _syncService;

  Future<void> onRefresh() async {
    final books = await _repository.loadBooks();
    await _syncService.recordRefresh();
    emit(state.copyWith(books: books));
  }
}
```

An umbrella remains valid when it provides a useful feature API, but it is an
option rather than the only permitted Cubit boundary.

## `stateless_application_service`

What it catches: mutable instance fields in `use_cases/` on classes ending in
`UseCase`, `UseCases`, `Policy`, `Tracker`, `Saver`, `Service`, `Workflow`, or
`Coordinator`.

Bad:

```dart
class PlaybackService {
  Duration lastPosition = Duration.zero;

  Future<void> save(Duration position) async {
    lastPosition = position;
  }
}
```

Good:

```dart
class SavePlaybackUseCase {
  const SavePlaybackUseCase(this._repository);

  final PlaybackRepository _repository;

  Future<void> run(Duration position) => _repository.save(position);
}
```

Application services execute behavior; the Cubit state remains the source of
truth for mutable feature data.

## `application_module_hides_collaborators`

What it catches: public instance fields on application classes in handwritten
`lib/**/use_cases/**.dart` files. An application class is any class whose name
ends in `UseCase`, `UseCases`, `Workflow`, `Coordinator`, or `Application`.
Static fields do not define per-instance collaborators, so this rule ignores
them.

A public field makes the wrapped dependency part of the module's API. Callers
can then skip the module's policy and call the repository or service directly.
The field also makes it harder to replace that collaborator without changing
every caller. Keep instance fields private and expose operations named in the
language of the application.

Bad:

```dart
class LibraryApplication {
  final BookRepository repository;

  const LibraryApplication(this.repository);
}
```

Good:

```dart
class LibraryApplication {
  const LibraryApplication(this._repository);

  final BookRepository _repository;

  Future<List<Book>> loadLibrary() => _repository.loadBooks();
}
```

The public interface describes behavior. Repositories, policies, services, and
other collaborators remain implementation details.

This rule checks visibility, not the declared type. It reports any public
instance field because even a harmless-looking value can become an alternate
path around the behavior API. Generated files and test sources are ignored.

If a class has no policy, coordination, or translation to protect, remove the
wrapper and inject its contract directly. A private field plus a one-to-one
forwarding method only hides the dependency syntactically; the next rule
catches modules made entirely of that pattern.

## `avoid_trivial_application_modules`

What it catches: a concrete application class in handwritten
`lib/**/use_cases/**.dart` code when every eligible public operation only
forwards unchanged arguments to a private collaborator. It recognizes both
expression bodies and one-statement bodies, with or without `return` or
`await`.

The diagnostic requires all of these conditions:

- the class name ends in `UseCase`, `UseCases`, `Workflow`, `Coordinator`, or
  `Application`;
- the class has at least one private instance field and one public operation;
- every public operation consists of one call to a private field;
- positional and named arguments pass through unchanged.

The rule evaluates the class as a whole. One operation that coordinates work,
checks policy, transforms data, or delegates to private behavior gives the
module a reason to exist, even when another operation is a simple pass-through.

Bad:

```dart
class SaveThemeUseCase {
  const SaveThemeUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> run(AppTheme theme) => _repository.saveTheme(theme);
}
```

Good:

```dart
class SettingsApplication {
  const SettingsApplication(this._repository);

  final SettingsRepository _repository;

  Future<SettingsSnapshot> load() async {
    final (theme, playback) = await (
      _repository.loadTheme(),
      _repository.loadPlayback(),
    ).wait;
    return SettingsSnapshot(theme: theme, playback: playback);
  }

  Future<void> changeTheme(AppTheme theme) => _repository.saveTheme(theme);
}
```

Validation, branching, coordination, failure translation, result construction,
argument transformation, and delegation to private behavior all provide depth.
The rule does not prescribe how much of that work a class needs. It only
rejects a class whose complete public behavior API is an unchanged relay.

Abstract contracts and `@override` methods may legitimately mirror another
API, so they are ignored. Static methods, getters, setters, operators, private
methods, generated code, and test sources are also outside this check.

To fix the diagnostic, either move real application behavior into the module
or delete the wrapper and inject the underlying contract. Renaming a repository
method without changing its behavior does not create an application boundary.

## `widget_dispatches_intents_only`

What it catches in `ui/`, `presentation/`, and `lib/core/presentation/`:

- imports of `flutter_bloc` or `go_router`;
- `context.read`, `watch`, `select`, `go`, `goNamed`, `push`, or `pushNamed`;
- direct `*Cubit`, `BlocBuilder`, `BlocConsumer`, or `BlocListener` types;
- feature UI constructing `File` or `Directory`.

Bad:

```dart
class LibraryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, state) => ElevatedButton(
        onPressed: () => context.read<LibraryCubit>().load(),
        child: const Text('Reload'),
      ),
    );
  }
}
```

Good:

```dart
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    required this.state,
    required this.onIntent,
    super.key,
  });

  final LibraryState state;
  final ValueChanged<LibraryIntent> onIntent;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: () => onIntent(const LibraryIntent.refresh()),
    child: const Text('Reload'),
  );
}
```

Bloc subscription, navigation, and dependency resolution belong in the
feature root. Leaf widgets receive state and emit typed intents.
