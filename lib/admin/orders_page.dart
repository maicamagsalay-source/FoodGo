import 'package:flutter/material.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';

const orderStatuses = ['pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled'];

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});
  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<AppOrder> _orders = [];
  String _filter = 'all';
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
      _error = 'Could not load orders.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return ErrorRetry(_error!, _load);
    final list = _filter == 'all' ? _orders : _orders.where((o) => o.status == _filter).toList();
    return Column(children: [
      SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          children: ['all', ...orderStatuses]
              .map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                        label: Text(cap(s)),
                        selected: _filter == s,
                        onSelected: (_) => setState(() => _filter = s)),
                  ))
              .toList(),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: list.isEmpty
              ? ListView(children: const [
                  Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No orders.')))
                ])
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: list
                      .map((o) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AdminOrderDetail(orderId: o.id)));
                                _load();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('#${o.id} • ${o.customerName}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        Text('${peso(o.total)} • ${fmtDate(o.createdAt)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Colors.grey.shade600, fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Wrap(spacing: 6, runSpacing: 4, children: [
                                          StatusChip(o.status),
                                          StatusChip(o.paymentStatus),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right),
                                ]),
                              ),
                            ),
                          ))
                      .toList(),
                ),
        ),
      ),
    ]);
  }
}

class AdminOrderDetail extends StatefulWidget {
  final int orderId;
  const AdminOrderDetail({super.key, required this.orderId});
  @override
  State<AdminOrderDetail> createState() => _AdminOrderDetailState();
}

class _AdminOrderDetailState extends State<AdminOrderDetail> {
  AppOrder? _order;
  List<PaymentRecord> _payments = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final o =
          await db.from('orders').select('*, order_items(*)').eq('id', widget.orderId).single();
      final p = await db
          .from('payments')
          .select('*, orders(customer_name)')
          .eq('order_id', widget.orderId)
          .order('created_at', ascending: false);
      _order = AppOrder.fromMap(o);
      _payments = (p as List).map((e) => PaymentRecord.fromMap(e)).toList();
    } catch (_) {
      _error = 'Could not load order.';
    }
    if (mounted) setState(() {});
  }

  Future<void> _setStatus(String status) async {
    try {
      await db.from('orders').update({'status': status}).eq('id', widget.orderId);
      await _load();
      if (mounted) snack(context, 'Status updated to ${cap(status)}');
    } catch (_) {
      if (mounted) snack(context, 'Could not update status.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      appBar: AppBar(title: Text('Order #${widget.orderId}')),
      body: _error != null
          ? ErrorRetry(_error!, _load)
          : o == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(16), children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(o.customerName),
                        Text(o.phone),
                        Text(o.address),
                        const SizedBox(height: 4),
                        Text(fmtDate(o.createdAt), style: TextStyle(color: Colors.grey.shade600)),
                      ]),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...o.items.map((i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(children: [
                                Expanded(child: Text('${i.qty} × ${i.name}')),
                                Text(peso(i.price * i.qty))
                              ]),
                            )),
                        const Divider(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [const Text('Delivery Fee'), Text(peso(o.deliveryFee))]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(peso(o.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      ]),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('Payment  ', style: TextStyle(fontWeight: FontWeight.bold)),
                          StatusChip(o.paymentStatus)
                        ]),
                        if (_payments.isEmpty) const Text('No payment attempts yet.'),
                        ..._payments.map((p) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                  '${p.method.toUpperCase()} • ${p.transactionId} • ${cap(p.status)}',
                                  style: const TextStyle(fontSize: 12)),
                            )),
                      ]),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Update order status',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: orderStatuses
                              .map((s) => ChoiceChip(
                                    label: Text(cap(s)),
                                    selected: o.status == s,
                                    onSelected: o.status == s ? null : (_) => _setStatus(s),
                                  ))
                              .toList(),
                        ),
                      ]),
                    ),
                  ),
                ]),
    );
  }
}
