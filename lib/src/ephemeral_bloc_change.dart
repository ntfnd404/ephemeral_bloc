import 'package:flutter/foundation.dart';

/// Snapshot of an action transition: what was emitted just before [current]
/// and what is being emitted now.
///
/// [previous] is null on the very first [emitAction] call after BLoC creation.
@immutable
final class EphemeralBlocChange<A> {
  final A? previous;
  final A current;

  @override
  int get hashCode => Object.hash(previous, current);

  const EphemeralBlocChange({this.previous, required this.current});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EphemeralBlocChange<A> &&
          previous == other.previous &&
          current == other.current;

  @override
  String toString() =>
      'EphemeralBlocChange(previous: $previous, current: $current)';
}
