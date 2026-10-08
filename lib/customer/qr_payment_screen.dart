import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../widgets.dart';
import 'customer_shell.dart';
import 'order_detail_screen.dart';
import 'payment_status_screen.dart';

/// Instant QR Ph: PayMongo makes a new QR for this order, the customer scans and pays,
/// and the app checks every 5 seconds until it is paid.
class QrPaymentScreen extends StatefulWidget {
  final int orderId;
  final double total;
  const QrPaymentScreen({super.key, required this.orderId, required this.total});
  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  QrPayment? _qr;
  String? _error;
  bool _loading = true, _paid = false, _switching = false;
  Duration _left = Duration.zero;
  Timer? _poll, _tick;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  void _stopTimers() {
    _poll?.cancel();
    _tick?.cancel();
  }

  Future<void> _generate() async {
    _stopTimers();
    setState(() {
      _loading = true;
      _error = null;
      _qr = null;
    });
    try {
      final qr = await createQrPayment(widget.orderId);
      if (!mounted) return;
      setState(() {
        _qr = qr;
        _loading = false;
      });
      _updateLeft();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _updateLeft());
      _poll = Timer.periodic(const Duration(seconds: 5), (_) => _check());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _updateLeft() {
    if (!mounted || _qr == null) return;
    final l = _qr!.expiresAt.difference(DateTime.now());
    setState(() => _left = l.isNegative ? Duration.zero : l);
    if (l.isNegative) {
      _stopTimers();
      _check(); // one last look in case it was paid just before expiring
    }
  }

  Future<void> _check() async {
    try {
      final s = await checkQrPayment(widget.orderId);
      if (s == 'paid' && mounted) {
        _stopTimers();
        setState(() => _paid = true);
      }
    } catch (_) {}
  }

  Future<void> _useCheckoutPage() async {
    setState(() => _switching = true);
    try {
      await openPayment(widget.orderId);
      _stopTimers();
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => PaymentStatusScreen(orderId: widget.orderId)));
    } catch (_) {
      if (mounted) {
        snack(context, 'Could not open the payment page. Please try again.');
        setState(() => _switching = false);
      }
    }
  }

  void _goToOrders() {
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const CustomerShell(initialIndex: 3)), (_) => false);
  }

  void _viewOrder() {
    final nav = Navigator.of(context);
    nav.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const CustomerShell(initialIndex: 3)), (_) => false);
    nav.push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: widget.orderId)));
  }

  String get _clock =>
      '${_left.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_left.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.orderId}'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: SingleChildScrollView(child: _body())),
      ),
    );
  }

  Widget _body() {
    if (_paid) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle, size: 96, color: Colors.green),
        const SizedBox(height: 16),
        const Text('Paid!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Payment Successful! Your order has been confirmed.', textAlign: TextAlign.center),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _viewOrder, child: const Text('View Order'))),
      ]);
    }
    if (_loading) {
      return const Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Creating your QR code…'),
      ]);
    }
    if (_error != null) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: _generate, child: const Text('Try again')),
        ..._alternatives(),
      ]);
    }

    final expired = _left == Duration.zero;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Pay with QR Ph', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      const Text('Scan with GCash, Maya or any bank app', textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Stack(alignment: Alignment.center, children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Opacity(opacity: expired ? 0.15 : 1, child: Image.memory(_qr!.bytes, width: 240, height: 240, fit: BoxFit.contain)),
        ),
        if (expired) const Text('QR expired', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 12),
      Text(peso(widget.total), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const Text('Exact amount is already filled in', style: TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      if (!expired) Text('Expires in $_clock', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
      if (!expired) const Text('Checking your payment every 5 seconds…', style: TextStyle(fontSize: 12)),
      const SizedBox(height: 16),
      if (expired) SizedBox(width: double.infinity, child: FilledButton(onPressed: _generate, child: const Text('Get a new QR'))),
      ..._alternatives(),
    ]);
  }

  List<Widget> _alternatives() => [
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46)),
          onPressed: _switching ? null : _useCheckoutPage,
          child: const Text('Pay with card / e-wallet page instead'),
        ),
        TextButton(onPressed: _goToOrders, child: const Text('Pay later — go to my orders')),
      ];
}