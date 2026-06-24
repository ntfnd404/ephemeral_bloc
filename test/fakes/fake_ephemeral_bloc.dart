import 'dart:async';

import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Fake [Bloc] that manually controls action emission without [EphemeralBlocMixin].
///
/// Used to verify that [EphemeralBlocListener] works with any [EphemeralBlocStateStreamable]
/// implementation, not only with [EphemeralBlocMixin].
final class FakeEphemeralBloc extends Bloc<Object, int>
    implements EphemeralBlocStateStreamable<int, String> {
  final StreamController<String> _actionController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get actionStream => _actionController.stream;

  FakeEphemeralBloc() : super(0);

  void emitAction(String action) => _actionController.add(action);

  @override
  Future<void> close() async {
    await _actionController.close();

    return super.close();
  }
}
