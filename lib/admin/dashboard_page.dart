import 'package:flutter/material.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';
import 'orders_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<AppOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await db.from('orders').select('*, order_items(*)').order('created_at', ascending: false);
      _orders = (data as List).map((e) => AppOrder.fromMap(e)).toList();
      _error = null;
    } catch (_) {
      _error = 'Could not load dashboard.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _card(String title, String value, IconData icon, Color color) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ]),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(_error!, _load);

    final pending = _orders.where((o) => o.status == 'pending').length;
    final inProgress =
        _orders.where((o) => ['confirmed', 'preparing', 'ready'].contains(o.status)).length;
    final awaitingPayment =
        _orders.where((o) => o.paymentStatus == 'pending' && o.status != 'cancelled').length;
    final completed = _orders.where((o) => o.status == 'completed').length;
    final sales = _orders
        .where((o) => o.paymentStatus == 'paid' && o.status != 'cancelled')
        .fold(0.0, (s, o) => s + o.total);

    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 680
                ? 3
                : 2;
        return ListView(padding: const EdgeInsets.all(16), children: [
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth >= 680 ? 2.2 : 1.7,
            children: [
              _card('Total Orders', '${_orders.length}', Icons.receipt_long, Colors.blue),
              _card('Pending', '$pending', Icons.hourglass_top, Colors.orange),
              _card('In Progress', '$inProgress', Icons.local_shipping_outlined, Colors.teal),
              _card('Awaiting Payment', '$awaitingPayment', Icons.payments_outlined,
                  Colors.deepOrange),
              _card('Completed', '$completed', Icons.check_circle, Colors.green),
              _card('Total Sales', peso(sales), Icons.payments, Colors.purple),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_orders.isEmpty) const Text('No orders yet.'),
          ..._orders.take(5).map((o) => Card(
                child: ListTile(
                  onTap: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AdminOrderDetail(orderId: o.id)));
                    _load();
                  },
                  title: Text('Order #${o.id} • ${o.customerName}'),
                  subtitle: Text('${peso(o.total)} • ${fmtDate(o.createdAt)}'),
                  trailing: StatusChip(o.status),
                ),
              )),
        ]);
      }),
    );
  }
}
