import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_ephemeral_bloc.dart';
import 'stubs/stub_ephemeral_bloc.dart';

void main() {
  group('EphemeralBlocListener', () {
    test('reports its configuration in diagnostics', () {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final listener = EphemeralBlocListener<StubEphemeralBloc, int, String>(
        bloc: bloc,
        listenWhen: (_) => true,
        listener: (_, _) {},
      );
      final properties = DiagnosticPropertiesBuilder();

      listener.debugFillProperties(properties);

      expect(
        properties.properties.map((property) => property.name),
        containsAll(<String>['bloc', 'listener', 'listenWhen']),
      );
    });

    testWidgets('supports a custom streamable implementation', (tester) async {
      final bloc = FakeEphemeralBloc();
      addTearDown(bloc.close);
      final received = <String>[];

      await tester.pumpWidget(
        _provided(
          bloc,
          EphemeralBlocListener<FakeEphemeralBloc, int, String>(
            listener: (_, action) => received.add(action),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      bloc.emitAction('hello');
      await tester.pump();

      expect(received, ['hello']);
    });

    testWidgets('listenWhen suppresses selected actions', (tester) async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final received = <String>[];

      await tester.pumpWidget(
        _provided(
          bloc,
          EphemeralBlocListener<StubEphemeralBloc, int, String>(
            listenWhen: (action) => action != 'skip',
            listener: (_, action) => received.add(action),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      bloc
        ..emitTestAction('pass')
        ..emitTestAction('skip')
        ..emitTestAction('pass');
      await tester.pump();

      expect(received, ['pass', 'pass']);
    });

    testWidgets('explicit bloc replacement switches subscriptions', (
      tester,
    ) async {
      final first = StubEphemeralBloc();
      final second = StubEphemeralBloc();
      addTearDown(first.close);
      addTearDown(second.close);
      final received = <String>[];

      Widget subject(StubEphemeralBloc bloc) => MaterialApp(
        home: EphemeralBlocListener<StubEphemeralBloc, int, String>(
          bloc: bloc,
          listener: (_, action) => received.add(action),
          child: const SizedBox.shrink(),
        ),
      );

      await tester.pumpWidget(subject(first));
      first.emitTestAction('first');
      await tester.pump();

      await tester.pumpWidget(subject(second));
      first.emitTestAction('stale');
      second.emitTestAction('second');
      await tester.pump();

      expect(received, ['first', 'second']);
    });

    testWidgets('switching from explicit bloc uses the inherited provider', (
      tester,
    ) async {
      final explicit = StubEphemeralBloc();
      final inherited = StubEphemeralBloc();
      addTearDown(explicit.close);
      addTearDown(inherited.close);
      final received = <String>[];

      Widget subject({required bool useExplicit}) => _provided(
        inherited,
        EphemeralBlocListener<StubEphemeralBloc, int, String>(
          bloc: useExplicit ? explicit : null,
          listener: (_, action) => received.add(action),
          child: const SizedBox.shrink(),
        ),
      );

      await tester.pumpWidget(subject(useExplicit: true));
      explicit.emitTestAction('explicit');
      await tester.pump();

      await tester.pumpWidget(subject(useExplicit: false));
      explicit.emitTestAction('stale');
      inherited.emitTestAction('inherited');
      await tester.pump();

      expect(received, ['explicit', 'inherited']);
    });

    testWidgets('provider replacement switches subscriptions', (tester) async {
      final first = StubEphemeralBloc();
      final second = StubEphemeralBloc();
      addTearDown(first.close);
      addTearDown(second.close);
      final received = <String>[];
      final child = EphemeralBlocListener<StubEphemeralBloc, int, String>(
        listener: (_, action) => received.add(action),
        child: const SizedBox.shrink(),
      );

      await tester.pumpWidget(_provided(first, child));
      first.emitTestAction('first');
      await tester.pump();

      await tester.pumpWidget(_provided(second, child));
      first.emitTestAction('stale');
      second.emitTestAction('second');
      await tester.pump();

      expect(received, ['first', 'second']);
    });

    testWidgets('dispose cancels the action subscription', (tester) async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final received = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: EphemeralBlocListener<StubEphemeralBloc, int, String>(
            bloc: bloc,
            listener: (_, action) => received.add(action),
            child: const SizedBox.shrink(),
          ),
        ),
      );
      bloc.emitTestAction('before');
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      bloc.emitTestAction('after');
      await tester.pump();

      expect(received, ['before']);
    });

    testWidgets('fails fast for a BLoC without an action stream', (
      tester,
    ) async {
      final bloc = _PlainCubit();
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: EphemeralBlocListener<_PlainCubit, int, String>(
            bloc: bloc,
            listener: (_, _) {},
            child: const SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets('fails fast when the required provider is absent', (
      tester,
    ) async {
      await tester.pumpWidget(
        EphemeralBlocListener<StubEphemeralBloc, int, String>(
          listener: (_, _) {},
          child: const SizedBox.shrink(),
        ),
      );

      expect(tester.takeException(), isNotNull);
    });
  });
}

Widget _provided<B extends BlocBase<int>>(B bloc, Widget child) => MaterialApp(
  home: BlocProvider<B>.value(value: bloc, child: child),
);

final class _PlainCubit extends Cubit<int> {
  _PlainCubit() : super(0);
}
