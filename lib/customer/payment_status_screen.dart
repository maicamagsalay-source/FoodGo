import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../providers.dart';
import '../widgets.dart';
import 'customer_shell.dart';
import 'order_detail_screen.dart';

/// Shown after the customer is sent to PayMongo. It checks the database every
/// few seconds; the Edge Function webhook flips payment_status to 'paid'.
class PaymentStatusScreen extends StatefulWidget {
  final int orderId;
  final bool isCashOnDelivery;
  const PaymentStatusScreen({super.key, required this.orderId, this.isCashOnDelivery = false});
  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  String _status = 'pending';
  Timer? _timer;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isCashOnDelivery) {
      _check();
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _check());
    }
  }

  Future<void> _check() async {
    try {
      final r = await db.from('orders').select('payment_status').eq('id', widget.orderId).single();
      if (!mounted) return;
      setState(() => _status = r['payment_status']);
      if (_status != 'pending') _timer?.cancel();
    } catch (_) {}
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await openPayment(widget.orderId);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 3), (_) => _check());
    } catch (e) {
      if (mounted) snack(context, 'Could not open payment. Please try again.');
    }
    if (mounted) setState(() => _retrying = false);
  }

  void _viewOrder() {
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerShell(initialIndex: 3)), (_) => false);
    nav.push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: widget.orderId)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final String title, message;
    if (widget.isCashOnDelivery) {
      icon = Icons.local_shipping_outlined;
      color = Colors.teal;
      title = 'Order Placed!';
      message = 'Pay with cash when your order is delivered.';
    } else {
      switch (_status) {
        case 'paid':
          icon = Icons.check_circle;
          color = Colors.green;
          title = 'Payment Successful!';
          message = 'Your order has been confirmed.';
          break;
        case 'failed':
          icon = Icons.cancel;
          color = Colors.red;
          title = 'Payment Failed';
          message = 'Your payment did not go through. You can try again.';
          break;
        default:
          icon = Icons.hourglass_top;
          color = Colors.orange;
          title = 'Waiting for payment';
          message =
              'Complete your payment in the PayMongo page. This screen updates automatically.';
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.orderId}'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 96, color: color),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          if (widget.isCashOnDelivery || _status == 'paid')
            SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _viewOrder, child: const Text('View Order')))
          else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _retrying ? null : _retry,
                child: Text(_status == 'failed' ? 'Try Payment Again' : 'Open Payment Page Again'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: _viewOrder, child: const Text('Pay later — go to my orders')),
          ],
        ]),
      ),
    );
  }
}
