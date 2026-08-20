import 'dart:async';

import 'package:ephemeral_bloc/src/ephemeral_bloc_observer.dart';
import 'package:ephemeral_bloc/src/ephemeral_bloc_streamable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adds a one-shot action stream to any [BlocBase].
///
/// Actions are fire-and-forget UI effects (SnackBar, navigation, focus).
/// They are NOT stored in state — they arrive once and are consumed.
///
/// Usage:
/// ```dart
/// class MyBloc extends Bloc<MyEvent, MyState>
///     with EphemeralBlocMixin<MyState, MyAction> { ... }
/// ```
mixin EphemeralBlocMixin<S, A extends Object> on BlocBase<S>
    implements EphemeralBlocStateStreamable<S, A> {
  final StreamController<A> _actionController = StreamController<A>.broadcast();
  final BlocObserver _actionObserver = Bloc.observer;
  bool _isClosing = false;

  /// Broadcast stream of one-shot UI actions.
  ///
  /// Late subscribers do not receive past actions.
  @override
  Stream<A> get actionStream => _actionController.stream;

  /// Emits [action] to all current [actionStream] subscribers.
  ///
  /// This method is intended to be called only by the BLoC or Cubit that mixes
  /// in this type. UI code should send an event or invoke a public command on
  /// the BLoC instead.
  ///
  /// Calling this method after closing has started is a deliberate no-op.
  /// Fire-and-forget effects produced during teardown are safely discarded.
  @protected
  void emitAction(A action) {
    if (_isClosing || isClosed) return;

    if (_actionObserver case final EphemeralBlocObserver actionObserver) {
      actionObserver.onAction(this, action);
    }
    _actionController.add(action);
  }

  @mustCallSuper
  @override
  Future<void> close() async {
    _isClosing = true;
    await super.close();
    await _actionController.close();
  }
}
