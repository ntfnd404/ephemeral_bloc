# ephemeral_bloc

## Package type: Shared utility

Extends `flutter_bloc` with a typed one-shot action stream for side-effects
(navigation, SnackBars, clipboard) that must not live in BLoC state. Used by
every feature BLoC in the app.

## Internal structure

**Flat.** All symbols are at the same abstraction level.

```
lib/src/
  ephemeral_bloc_listener.dart   ← EphemeralBlocListener widget
  ephemeral_bloc_mixin.dart      ← EphemeralBlocMixin<S, A> for BLoC classes
  ephemeral_bloc_observer.dart   ← EphemeralBlocObserver for debugging
  ephemeral_bloc_streamable.dart ← EphemeralBlocStreamable / EphemeralBlocObservable interfaces
```

### Why flat

Single-concern utility with no internal hierarchy. All files are at the same
abstraction level — no domain/application/data split applies.

## Public API

Barrel: `package:ephemeral_bloc/ephemeral_bloc.dart`

| Symbol | Kind | Description |
|---|---|---|
| `EphemeralBlocMixin<S, A>` | mixin | Adds `actionStream` + `emitAction` to a `Bloc` |
| `EphemeralBlocListener<B, S, A>` | widget | Listens to `actionStream` and calls `listener` |
| `EphemeralBlocConsumer<B, S, A>` | widget | Combines `BlocBuilder` + `EphemeralBlocListener` |
| `EphemeralBlocObserver` | class | `BlocObserver` that forwards actions to a callback |

## Dependencies

Workspace packages: none.
Third-party: `flutter_bloc`.
SDK: Flutter SDK.
