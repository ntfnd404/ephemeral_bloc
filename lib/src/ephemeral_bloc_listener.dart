import 'dart:async';

import 'package:ephemeral_bloc/src/ephemeral_bloc_mixin.dart';
import 'package:ephemeral_bloc/src/ephemeral_bloc_streamable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

/// Listens to one-shot actions emitted by a BLoC that uses [EphemeralBlocMixin].
///
/// Compatible with [MultiBlocListener] via [SingleChildStatefulWidget].
///
/// If [bloc] is omitted the nearest [BlocProvider] ancestor is used.
///
/// Usage:
/// ```dart
/// EphemeralBlocListener<MyBloc, MyState, MyAction>(
///   listener: (context, action) => switch (action) {
///     MyActionA() => ...,
///     MyActionB(:final data) => ...,
///   },
///   child: ...,
/// )
/// ```
class EphemeralBlocListener<B extends BlocBase<S>, S, A>
    extends SingleChildStatefulWidget {
  const EphemeralBlocListener({
    super.key,
    required this.listener,
    this.bloc,
    this.listenWhen,
    super.child,
  });

  /// The BLoC to subscribe to. When null, resolved via [context.read].
  final B? bloc;

  /// Called on the main isolate for each emitted action.
  final void Function(BuildContext context, A action) listener;

  /// Optional filter for actions. Return false to suppress the listener call.
  /// When null, every action is forwarded.
  ///
  /// Unlike [BlocListener.listenWhen], there is no previous-action argument —
  /// actions are fire-and-forget events, not cumulative state transitions.
  final bool Function(A action)? listenWhen;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<B?>('bloc', bloc))
      ..add(
        ObjectFlagProperty<void Function(BuildContext, A)>.has(
          'listener',
          listener,
        ),
      )
      ..add(
        ObjectFlagProperty<bool Function(A)?>.has('listenWhen', listenWhen),
      );
  }

  @override
  SingleChildState<EphemeralBlocListener<B, S, A>> createState() =>
      _EphemeralBlocListenerState<B, S, A>();
}

class _EphemeralBlocListenerState<B extends BlocBase<S>, S, A>
    extends SingleChildState<EphemeralBlocListener<B, S, A>> {
  StreamSubscription<A>? _subscription;
  late B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _subscribe();
  }

  void _subscribe() {
    if (_bloc is! EphemeralBlocStreamable<A>) {
      throw StateError(
        '$B does not implement EphemeralBlocStreamable<$A>. '
        'Mix EphemeralBlocMixin into $B or implement the streamable contract '
        'to use EphemeralBlocListener.',
      );
    }
    final actionBloc = _bloc as EphemeralBlocStreamable<A>;
    _subscription = actionBloc.actionStream.listen((action) {
      if (!mounted) return;
      if (widget.listenWhen?.call(action) ?? true) {
        widget.listener(context, action);
      }
    });
  }

  @override
  void didUpdateWidget(EphemeralBlocListener<B, S, A> old) {
    super.didUpdateWidget(old);
    // When both [old.bloc] and [widget.bloc] are null the BLoC is resolved from
    // the nearest provider — [context.read<B>()] returns the same instance, so
    // [oldBloc == current] and no resubscription occurs. This is intentional.
    final oldBloc = old.bloc ?? context.read<B>();
    final current = widget.bloc ?? oldBloc;
    if (oldBloc != current) {
      _subscription?.cancel();
      _bloc = current;
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = widget.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _subscription?.cancel();
      _bloc = bloc;
      _subscribe();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) =>
      child ?? const SizedBox.shrink();
}
