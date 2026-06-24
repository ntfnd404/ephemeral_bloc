import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class StubEphemeralBloc extends Bloc<Object, int>
    with EphemeralBlocMixin<int, String> {
  StubEphemeralBloc() : super(0) {
    on<Object>((_, emit) => emit(state + 1));
  }
}
