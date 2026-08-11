# Bloc and Cubit

[← Testing, errors, and correctness](testing-errors-and-correctness.md) · [Rule index](../rules.md) · [Next: Maintainability →](maintainability.md)

These rules preserve Cubit-based unidirectional state flow and allow public
Cubit intent methods.

Blocs and Cubits may apply mixins for cross-cutting concerns such as logging,
metrics, and tracing. Feature-specific state transitions and business workflows
belong in the state holder or an injected collaborator. A lint cannot reliably
infer that semantic intent, so this distinction remains an architectural review.

## `bloc_fields_must_be_private`

What it catches: non-static public fields declared by a class extending
`Bloc` or `Cubit`.

Bad:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  final LibraryUseCases useCases;
}
```

Good:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  final LibraryUseCases _useCases;
}
```

State holders expose immutable `state` and intent methods, not their internal
collaborators or mutable implementation details.

## `bloc_state_must_use_state_suffix`

What it catches: the last generic type argument of a Bloc or Cubit when its
name does not end in `State`.

Bad:

```dart
class LibraryCubit extends Cubit<LibraryModel> {}
```

Good:

```dart
class LibraryCubit extends Cubit<LibraryState> {}
```

## `emit_new_state_instances`

What it catches: `emit(state)` inside a Bloc or Cubit.

Bad:

```dart
void refresh() {
  emit(state);
}
```

Good:

```dart
void refresh() {
  emit(state.copyWith(refreshRevision: state.refreshRevision + 1));
}
```

Emitting the identical state can be ignored by equality and subscription
mechanisms, making an intended update disappear.

## `no_bloc_to_bloc_dependencies`

What it catches: a non-static field on a Bloc or Cubit whose type name ends in
`Bloc` or `Cubit`.

Bad:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  final PlayerCubit _playerCubit;
}
```

Good:

```dart
class LibraryCubit extends Cubit<LibraryState> {
  final LibraryUseCases _useCases;
}
```

Cross-feature coordination belongs in a composition root, while shared domain
behavior belongs behind an application or domain port.
## `no_build_context_in_bloc`

What it catches: `BuildContext` type usages inside a Bloc, Cubit, or class
whose name ends in `Event`.

Bad:

```dart
void openBook(BuildContext context, Book book) {
  context.push('/book/${book.id}');
}
```

Good:

```dart
void openBook(Book book) {
  emit(state.copyWith(navigation: OpenBookNotice(book.id)));
}
```

The composition root observes the typed notice and performs navigation with a
valid UI context.
