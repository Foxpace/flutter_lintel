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

What it catches: public instance fields on application classes under
`use_cases/`. Application classes end in `UseCase`, `UseCases`, `Workflow`,
`Coordinator`, or `Application`.

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

## `avoid_trivial_application_modules`

What it catches: a concrete application class under `use_cases/` when every
public operation only forwards unchanged arguments to a private collaborator.
The rule evaluates the class as a whole, so a useful module may still contain
an occasional pass-through operation.

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
Abstract contracts, overrides, generated code, and test sources are ignored.

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
