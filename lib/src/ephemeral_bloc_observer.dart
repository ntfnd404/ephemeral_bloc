import 'package:flutter_bloc/flutter_bloc.dart';

/// Observes one-shot actions emitted by BLoCs that use
/// `EphemeralBlocMixin`.
///
/// Mix this into your [BlocObserver] subclass and override [onAction]
/// to receive actions globally:
///
/// ```dart
/// final class AppBlocObserver extends BlocObserver with EphemeralBlocObserver {
///   @override
///   void onAction(BlocBase<Object?> bloc, Object action) {
///     log('${bloc.runtimeType}: $action');
///   }
/// }
/// ```
///
/// The default implementation is a no-op, so you only override what you need.
mixin EphemeralBlocObserver {
  /// Called each time an action is emitted by an open BLoC or Cubit.
  void onAction(BlocBase<Object?> bloc, Object action) {}
}
