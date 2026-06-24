import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_ephemeral_bloc.dart';
import 'stubs/stub_ephemeral_bloc.dart';

void main() {
  group('EphemeralBlocListener', () {
    testWidgets('listens to EphemeralBlocStreamable without requiring mixin', (
      tester,
    ) async {
      final bloc = FakeEphemeralBloc();
      addTearDown(bloc.close);
      final received = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: EphemeralBlocListener<FakeEphemeralBloc, int, String>(
              listener: (_, action) => received.add(action),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      bloc.emitAction('hello');
      await tester.pump();

      expect(received, ['hello']);
    });

    testWidgets('listenWhen returning false suppresses listener call', (
      tester,
    ) async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final received = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: EphemeralBlocListener<StubEphemeralBloc, int, String>(
              listenWhen: (action) => action != 'skip',
              listener: (_, action) => received.add(action),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      bloc.emitAction('pass');
      bloc.emitAction('skip');
      bloc.emitAction('pass');
      await tester.pump();

      expect(received, ['pass', 'pass']);
    });
  });
}
