import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stubs/stub_ephemeral_bloc.dart';

void main() {
  group('EphemeralBlocConsumer', () {
    test('reports its configuration in diagnostics', () {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final consumer = EphemeralBlocConsumer<StubEphemeralBloc, int, String>(
        bloc: bloc,
        actionListener: (_, _) {},
        stateListener: (_, _) {},
        actionListenWhen: (_) => true,
        stateListenWhen: (_, _) => true,
        buildWhen: (_, _) => true,
        builder: (_, _) => const SizedBox.shrink(),
      );
      final properties = DiagnosticPropertiesBuilder();

      consumer.debugFillProperties(properties);

      expect(
        properties.properties.map((property) => property.name),
        containsAll(<String>[
          'bloc',
          'actionListener',
          'stateListener',
          'builder',
          'actionListenWhen',
          'stateListenWhen',
          'buildWhen',
        ]),
      );
    });

    testWidgets('actionListener receives the action without state', (
      tester,
    ) async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final received = <String>[];

      await tester.pumpWidget(
        _provided(
          bloc,
          EphemeralBlocConsumer<StubEphemeralBloc, int, String>(
            actionListener: (_, action) => received.add(action),
            builder: (_, state) => Text('$state'),
          ),
        ),
      );

      bloc.emitTestAction('hello');
      await tester.pump();

      expect(received, ['hello']);
    });

    testWidgets('stateListener fires on state change', (tester) async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final states = <int>[];

      await tester.pumpWidget(
        _provided(
          bloc,
          EphemeralBlocConsumer<StubEphemeralBloc, int, String>(
            stateListener: (_, state) => states.add(state),
            builder: (_, state) => Text('count:$state'),
          ),
        ),
      );

      bloc.add(Object());
      await tester.pump();

      expect(states, [1]);
    });

    testWidgets('builder rebuilds on state change', (tester) async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);

      await tester.pumpWidget(
        _provided(
          bloc,
          EphemeralBlocConsumer<StubEphemeralBloc, int, String>(
            builder: (_, state) => Text('count:$state'),
          ),
        ),
      );

      expect(find.text('count:0'), findsOneWidget);
      bloc.add(Object());
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);
    });

    testWidgets('actionListenWhen filters actions', (tester) async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final received = <String>[];

      await tester.pumpWidget(
        _provided(
          bloc,
          EphemeralBlocConsumer<StubEphemeralBloc, int, String>(
            actionListenWhen: (action) => action != 'skip',
            actionListener: (_, action) => received.add(action),
            builder: (_, state) => Text('$state'),
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

    testWidgets('stateListenWhen and buildWhen are independent', (
      tester,
    ) async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final listened = <int>[];

      await tester.pumpWidget(
        _provided(
          bloc,
          EphemeralBlocConsumer<StubEphemeralBloc, int, String>(
            stateListenWhen: (_, current) => current.isEven,
            stateListener: (_, state) => listened.add(state),
            buildWhen: (_, current) => current.isOdd,
            builder: (_, state) => Text('count:$state'),
          ),
        ),
      );

      bloc.add(Object());
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);
      expect(listened, isEmpty);

      bloc.add(Object());
      await tester.pump();
      expect(find.text('count:1'), findsOneWidget);
      expect(listened, [2]);
    });

    testWidgets('provider replacement switches the action subscription', (
      tester,
    ) async {
      final first = StubEphemeralBloc();
      final second = StubEphemeralBloc();
      addTearDown(first.close);
      addTearDown(second.close);
      final received = <String>[];
      final child = EphemeralBlocConsumer<StubEphemeralBloc, int, String>(
        actionListener: (_, action) => received.add(action),
        builder: (_, state) => Text('$state'),
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
  });
}

Widget _provided(StubEphemeralBloc bloc, Widget child) => MaterialApp(
  home: BlocProvider<StubEphemeralBloc>.value(value: bloc, child: child),
);
