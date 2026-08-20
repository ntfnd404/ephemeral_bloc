# ephemeral_bloc

Typed, one-shot UI actions for applications built with
[`flutter_bloc`](https://pub.dev/packages/flutter_bloc).

Use an action for an effect that must happen once—showing a dialog or
SnackBar, navigating, requesting focus, or copying to the clipboard—without
storing that effect in durable BLoC state.

## Why actions are separate

State describes what the UI is now and may be replayed or rebuilt many times.
An event or command describes what the user or another system asked the BLoC
to do. An ephemeral action is the BLoC's one-time instruction to the UI after
it has handled that input.

Actions are delivered through a broadcast stream:

- current subscribers receive every action, including equal consecutive
  values;
- late subscribers do not receive old actions;
- actions are never compared with one another or stored as state;
- emissions after closing starts are safely ignored.

The package intentionally stays small: one mixin, one listener, one consumer,
a streamable contract, and an optional observer hook.

## Installation

```yaml
dependencies:
  ephemeral_bloc: ^0.1.0
```

Then import the public library:

```dart
import 'package:ephemeral_bloc/ephemeral_bloc.dart';
```

## Mixin

Actions should contain all data the UI needs for the immediate effect.

```dart
sealed class CheckoutAction {
  const CheckoutAction();
}

final class ShowConfirmation extends CheckoutAction {
  const ShowConfirmation({required this.orderId, required this.revision});

  final String orderId;
  final int revision;
}

final class CheckoutCubit extends Cubit<CheckoutState>
    with EphemeralBlocMixin<CheckoutState, CheckoutAction> {
  CheckoutCubit() : super(const CheckoutState());

  void requestConfirmation() {
    emitAction(
      ShowConfirmation(orderId: state.orderId, revision: state.revision),
    );
  }

  void confirm(String orderId, int revision) {
    if (state.orderId != orderId || state.revision != revision) return;
    // Continue with the current, validated state.
  }
}
```

`emitAction` is protected: UI code sends an event or invokes a public Cubit
command, and the BLoC or Cubit decides which action to emit.

Both `Bloc` and `Cubit` are supported because the mixin targets `BlocBase`.

## Listener

```dart
EphemeralBlocListener<CheckoutCubit, CheckoutState, CheckoutAction>(
  listener: (context, action) {
    switch (action) {
      case ShowConfirmation(:final orderId, :final revision):
        showConfirmation(context, orderId, revision);
    }
  },
  child: const CheckoutView(),
)
```

By default the listener reads the nearest matching `BlocProvider`. Pass
`bloc:` to subscribe explicitly. A missing provider or a BLoC that does not
implement `EphemeralBlocStreamable<A>` fails fast instead of silently doing
nothing. `EphemeralBlocListener` can also be used inside `MultiBlocListener`.

When the explicit BLoC or inherited provider is replaced, the old
subscription is cancelled and the new BLoC becomes the only action source.

## Filtering

Use `listenWhen` when only some actions belong to a listener:

```dart
EphemeralBlocListener<CheckoutCubit, CheckoutState, CheckoutAction>(
  listenWhen: (action) => action is ShowConfirmation,
  listener: (context, action) { /* handle it */ },
  child: const CheckoutView(),
)
```

The predicate receives only the current action. Actions are independent
events, so there is no misleading `previous` value.

## Consumer

`EphemeralBlocConsumer` combines an action listener, an optional state
listener, and a state builder without introducing multiple consumer variants.

```dart
EphemeralBlocConsumer<CheckoutCubit, CheckoutState, CheckoutAction>(
  actionListenWhen: (action) => action is ShowConfirmation,
  actionListener: (context, action) { /* perform the UI effect */ },
  stateListenWhen: (previous, current) => previous.error != current.error,
  stateListener: (context, state) { /* react to durable state */ },
  buildWhen: (previous, current) => previous.items != current.items,
  builder: (context, state) => CheckoutView(state: state),
)
```

`actionListener` and `stateListener` are optional. `builder` is always
required.

## Async dialogs and stale state

Do not capture a BLoC state snapshot in an action callback and assume it will
still be current after an asynchronous dialog. Put a stable identifier and,
when needed, a revision in the action. Send the result back as an intent and
validate it inside the BLoC:

```dart
Future<void> onAction(BuildContext context, CheckoutAction action) async {
  if (action case ShowConfirmation(:final orderId, :final revision)) {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(),
    );
    if (context.mounted && accepted == true) {
      context.read<CheckoutCubit>().confirm(orderId, revision);
    }
  }
}
```

This keeps concurrency and freshness checks in the BLoC, where the current
state is authoritative.

## Observer

Mix `EphemeralBlocObserver` into the observer installed before creating your
BLoCs:

```dart
final class AppBlocObserver extends BlocObserver with EphemeralBlocObserver {
  @override
  void onAction(BlocBase<Object?> bloc, Object action) {
    log('${bloc.runtimeType}: $action');
  }
}

void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const App());
}
```

Like `BlocBase`, each BLoC captures its observer when it is created. Replacing
`Bloc.observer` later does not split state and action observations between two
observers. The package does not retain a previous action. An application that
needs history can keep selected metadata in its own observer.

## Lifecycle

`close()` first lets `BlocBase` finish closing and then closes the action
stream. Once closing starts, new actions are discarded: they do not reach the
observer or stream, and they do not throw `StateError`. The stream is
broadcast and has no replay buffer.

## Testing

Actions can be tested as ordinary streams. Trigger the public event or command
that emits them rather than calling the protected `emitAction` from UI code:

```dart
final cubit = CheckoutCubit();
addTearDown(cubit.close);

expectLater(
  cubit.actionStream,
  emits(isA<ShowConfirmation>()),
);
cubit.requestConfirmation();
```

Use Flutter widget tests for listener behavior and `BlocProvider` replacement.
The core platform-independent local validation is:

```shell
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
dart run tool/check_coverage.dart coverage/lcov.info 90
dart run tool/check_dartdoc.dart
dart pub publish --dry-run

cd example
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

The publish dry-run validates the archive; it does not publish it. Dependency
lower bounds, Pana, and all platform builds are release checks documented in
[the release runbook](https://github.com/ntfnd404/ephemeral_bloc/blob/main/.github/RELEASING.md).

## Migrating from 0.0.1

The action listener no longer receives a potentially stale state snapshot:

```dart
// Before
actionListener: (context, state, action) { /* ... */ }

// 0.1.0
actionListener: (context, action) { /* ... */ }
```

The observer receives the action directly, and `EphemeralBlocChange` has been
removed:

```dart
// Before
onAction(BlocBase<Object?> bloc, EphemeralBlocChange<Object> change) {
  inspect(change.current);
}

// 0.1.0
onAction(BlocBase<Object?> bloc, Object action) {
  inspect(action);
}
```

Clone the repository and run the complete six-platform example:

```shell
cd example
flutter pub get
flutter run
```

See [example/lib/main.dart](example/lib/main.dart) for its implementation and
[the release runbook](https://github.com/ntfnd404/ephemeral_bloc/blob/main/.github/RELEASING.md)
for the manual first-release process.

## License

[MIT](LICENSE)
