import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  AppOrder? _order;
  String? _error;

  static const _steps = ['pending', 'confirmed', 'preparing', 'ready', 'completed'];
  static const _labels = ['Order Placed', 'Confirmed', 'Preparing', 'Ready', 'Completed'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await db.from('orders').select('*, order_items(*)').eq('id', widget.orderId).single();
      _order = AppOrder.fromMap(data);
      _error = null;
    } catch (_) {
      _error = 'Could not load this order.';
    }
    if (mounted) setState(() {});
  }

  Widget _tracker(AppOrder o) {
    if (o.status == 'cancelled') {
      return Card(
        color: Colors.red.shade50,
        child: const ListTile(
          leading: Icon(Icons.cancel, color: Colors.red),
          title: Text('This order was cancelled'),
        ),
      );
    }
    final current = _steps.indexOf(o.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          for (var i = 0; i < _steps.length; i++)
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Column(children: [
                  Icon(i <= current ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: i <= current ? Colors.green : Colors.grey),
                  if (i < _steps.length - 1)
                    Expanded(
                        child: Container(
                            width: 2, color: i < current ? Colors.green : Colors.grey.shade300)),
                ]),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(_labels[i],
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: i == current ? FontWeight.bold : FontWeight.normal,
                          color: i <= current ? Colors.black : Colors.grey)),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _error != null
          ? ErrorRetry(_error!, _load)
          : o == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    _tracker(o),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(fmtDate(o.createdAt), style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          ...o.items.map((i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(children: [
                                  Expanded(child: Text('${i.qty} × ${i.name}')),
                                  Text(peso(i.price * i.qty)),
                                ]),
                              )),
                          const Divider(),
                          _line('Subtotal', peso(o.subtotal)),
                          _line('Delivery Fee', peso(o.deliveryFee)),
                          _line('Total', peso(o.total), bold: true),
                          const SizedBox(height: 8),
                          Text('Payment method: ${o.paymentMethod}'),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Text('Payment status: '),
                            StatusChip(o.paymentStatus)
                          ]),
                          const SizedBox(height: 8),
                          Text('Deliver to: ${o.address}'),
                          Text('Phone: ${o.phone}'),
                        ]),
                      ),
                    ),
                    if (o.paymentMethod != 'Cash on Delivery' &&
                        o.paymentStatus != 'paid' &&
                        o.status != 'cancelled') ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await openPayment(o.id);
                          } catch (_) {
                            if (!context.mounted) return;
                            snack(context, 'Could not open payment. Please try again.');
                          }
                        },
                        child: const Text('Pay Now'),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                          child: Text('After paying, come back and pull down to refresh.',
                              style: TextStyle(fontSize: 12))),
                    ],
                  ]),
                ),
    );
  }

  Widget _line(String l, String v, {bool bold = false}) {
    final s =
        TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 17 : 15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(l, style: s), Text(v, style: s)]),
    );
  }
}
