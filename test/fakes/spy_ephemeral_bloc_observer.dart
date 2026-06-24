import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Spy [BlocObserver] that records every [onAction] call for later assertion.
final class SpyEphemeralBlocObserver extends BlocObserver
    with EphemeralBlocObserver {
  final List<({BlocBase<Object?> bloc, EphemeralBlocChange<Object?> change})>
  records = [];

  @override
  void onAction(BlocBase<Object?> bloc, EphemeralBlocChange<Object?> change) {
    records.add((bloc: bloc, change: change));
  }
}
