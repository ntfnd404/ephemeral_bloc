import 'dart:async';

import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/spy_ephemeral_bloc_observer.dart';
import 'stubs/stub_ephemeral_bloc.dart';

void main() {
  group('EphemeralBlocMixin', () {
    late BlocObserver previousObserver;

    setUp(() => previousObserver = Bloc.observer);
    tearDown(() => Bloc.observer = previousObserver);

    test('Bloc delivers actions to a stream subscriber', () async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final received = <String>[];
      final subscription = bloc.actionStream.listen(received.add);
      addTearDown(subscription.cancel);

      bloc.emitTestAction('hello');
      await Future<void>.delayed(Duration.zero);

      expect(received, ['hello']);
    });

    test('Cubit supports the same action contract', () async {
      final cubit = StubEphemeralCubit();
      addTearDown(cubit.close);
      final expectation = expectLater(cubit.actionStream, emits('hello'));

      cubit.emitTestAction('hello');

      await expectation;
    });

    test('two equal consecutive actions are both delivered', () async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final expectation = expectLater(
        bloc.actionStream,
        emitsInOrder(['same', 'same']),
      );

      bloc
        ..emitTestAction('same')
        ..emitTestAction('same');

      await expectation;
    });

    test('calling emitAction after close is a no-op', () async {
      final bloc = StubEphemeralBloc();
      final received = <String>[];
      bloc.actionStream.listen(received.add);

      await bloc.close();
      expect(() => bloc.emitTestAction('ignored'), returnsNormally);
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test(
      'closing a Bloc with an active handler drops its late action',
      () async {
        final observer = SpyEphemeralBlocObserver();
        Bloc.observer = observer;
        final bloc = _ClosingBloc();
        final received = <String>[];
        bloc.actionStream.listen(received.add);

        bloc.start();
        await bloc.handlerStarted.future;

        final closing = bloc.close();
        bloc.releaseHandler.complete();

        await expectLater(closing, completes);
        expect(received, isEmpty);
        expect(observer.records, isEmpty);
      },
    );

    test('broadcast subscribers receive independently', () async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      final first = <String>[];
      final second = <String>[];
      bloc.actionStream.listen(first.add);
      bloc.actionStream.listen(second.add);

      bloc.emitTestAction('ping');
      await Future<void>.delayed(Duration.zero);

      expect(first, ['ping']);
      expect(second, ['ping']);
    });

    test('late subscriber does not receive a past action', () async {
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);
      bloc.emitTestAction('past');
      await Future<void>.delayed(Duration.zero);

      final received = <String>[];
      bloc.actionStream.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test('observer receives actions in emission order', () {
      final observer = SpyEphemeralBlocObserver();
      Bloc.observer = observer;
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);

      bloc
        ..emitTestAction('first')
        ..emitTestAction('second');

      expect(observer.records, [
        (bloc: bloc, action: 'first'),
        (bloc: bloc, action: 'second'),
      ]);
    });

    test('default observer callback is a no-op', () {
      final observer = _NoOpObserver();
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);

      expect(() => observer.onAction(bloc, 'hello'), returnsNormally);
    });

    test('observer is captured when the BLoC is created', () {
      final original = SpyEphemeralBlocObserver();
      final replacement = SpyEphemeralBlocObserver();
      Bloc.observer = original;
      final bloc = StubEphemeralBloc();
      addTearDown(bloc.close);

      Bloc.observer = replacement;
      bloc.emitTestAction('hello');

      expect(original.records, [(bloc: bloc, action: 'hello')]);
      expect(replacement.records, isEmpty);
    });

    test('observer is not called after close starts', () async {
      final observer = SpyEphemeralBlocObserver();
      Bloc.observer = observer;
      final bloc = StubEphemeralBloc();

      await bloc.close();
      bloc.emitTestAction('ignored');

      expect(observer.records, isEmpty);
    });

    test('close completes the action stream', () async {
      final bloc = StubEphemeralBloc();
      final done = Completer<void>();
      bloc.actionStream.listen((_) {}, onDone: done.complete);

      await bloc.close();

      expect(done.isCompleted, isTrue);
    });
  });
}

final class _ClosingBloc extends Bloc<_Start, int>
    with EphemeralBlocMixin<int, String> {
  _ClosingBloc() : super(0) {
    on<_Start>((_, _) async {
      handlerStarted.complete();
      await releaseHandler.future;
      emitAction('late');
    });
  }

  final Completer<void> handlerStarted = Completer<void>();
  final Completer<void> releaseHandler = Completer<void>();

  void start() => add(const _Start());
}

final class _Start {
  const _Start();
}

final class _NoOpObserver extends BlocObserver with EphemeralBlocObserver {}
