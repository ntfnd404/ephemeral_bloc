import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter/widgets.dart';

final class _ConsumerObserver with EphemeralBlocObserver {}

void main() {
  final observer = _ConsumerObserver();

  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Text(observer.runtimeType.toString())),
    ),
  );
}
