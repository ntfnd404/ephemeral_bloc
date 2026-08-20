import 'package:flutter_bloc/flutter_bloc.dart';

/// Exposes a stream of one-shot actions.
abstract interface class EphemeralBlocStreamable<A extends Object> {
  /// Broadcast stream of actions emitted after a listener subscribes.
  Stream<A> get actionStream;
}

/// Exposes regular BLoC state plus one-shot actions.
abstract interface class EphemeralBlocStateStreamable<S, A extends Object>
    implements StateStreamable<S>, EphemeralBlocStreamable<A> {}
