import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets.dart';

bool canCancelOrder({required String status, required String paymentStatus}) =>
    (status == 'pending' || status == 'confirmed') && paymentStatus != 'paid';

Future<bool> confirmOrderCancellation(BuildContext context, int orderId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel this order?'),
      content: const Text(
        'You can cancel only before the restaurant starts preparing it. '
        'Paid orders cannot be cancelled here.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Keep order'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Cancel order'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  try {
    await cancelOrder(orderId);
    if (!context.mounted) return true;
    snack(context, 'Order #$orderId cancelled');
    return true;
  } catch (_) {
    if (context.mounted) {
      snack(context, 'Could not cancel this order. It may already be processing or paid.');
    }
    return false;
  }
}
