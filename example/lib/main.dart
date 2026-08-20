import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Runs the example application.
void main() => runApp(const CheckoutApp());

/// Root widget for the example.
final class CheckoutApp extends StatelessWidget {
  /// Creates the example application.
  const CheckoutApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: BlocProvider(
      create: (_) => CheckoutCubit(),
      child: const CheckoutPage(),
    ),
  );
}

/// Durable checkout data rendered by the UI.
final class CheckoutState {
  /// Creates checkout state.
  const CheckoutState({
    this.orderId = 'order-42',
    this.revision = 1,
    this.isConfirmed = false,
  });

  /// Stable identifier of the order being edited.
  final String orderId;

  /// Revision used to reject stale dialog responses.
  final int revision;

  /// Whether the current revision has been confirmed.
  final bool isConfirmed;

  /// Returns a copy with a changed confirmation value.
  CheckoutState copyWith({required bool isConfirmed}) => CheckoutState(
    orderId: orderId,
    revision: revision,
    isConfirmed: isConfirmed,
  );
}

/// One-shot UI actions produced by [CheckoutCubit].
sealed class CheckoutAction {
  const CheckoutAction();
}

/// Requests confirmation for a specific order revision.
final class ShowConfirmation extends CheckoutAction {
  /// Creates a self-contained confirmation action.
  const ShowConfirmation({required this.orderId, required this.revision});

  /// Order being confirmed.
  final String orderId;

  /// Revision that must still be current when the dialog completes.
  final int revision;
}

/// Manages checkout state and emits one-shot UI actions.
final class CheckoutCubit extends Cubit<CheckoutState>
    with EphemeralBlocMixin<CheckoutState, CheckoutAction> {
  /// Creates a checkout Cubit.
  CheckoutCubit() : super(const CheckoutState());

  /// Asks the UI to confirm the current order revision.
  void requestConfirmation() {
    emitAction(
      ShowConfirmation(orderId: state.orderId, revision: state.revision),
    );
  }

  /// Confirms only if the asynchronous result still matches current state.
  void confirm({required String orderId, required int revision}) {
    if (state.orderId != orderId || state.revision != revision) return;
    emit(state.copyWith(isConfirmed: true));
  }
}

/// Page that renders state and handles confirmation actions.
final class CheckoutPage extends StatelessWidget {
  /// Creates the checkout page.
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ephemeral_bloc example')),
    body: Center(
      child:
          EphemeralBlocConsumer<CheckoutCubit, CheckoutState, CheckoutAction>(
            actionListener: _onAction,
            builder: (context, state) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.isConfirmed ? 'Confirmed' : 'Awaiting confirmation'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: context.read<CheckoutCubit>().requestConfirmation,
                  child: const Text('Confirm order'),
                ),
              ],
            ),
          ),
    ),
  );

  Future<void> _onAction(BuildContext context, CheckoutAction action) async {
    switch (action) {
      case ShowConfirmation(:final orderId, :final revision):
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
        if (context.mounted && accepted == true) {
          context.read<CheckoutCubit>().confirm(
            orderId: orderId,
            revision: revision,
          );
        }
    }
  }
}
