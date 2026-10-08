import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../widgets.dart';
import 'payment_status_screen.dart';
import 'qr_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: context.read<AuthProvider>().name);
  late final _phone = TextEditingController(text: context.read<AuthProvider>().phone);
  final _address = TextEditingController();
  String _paymentMethod = 'PayMongo';
  bool _busy = false;

  Future<void> _placeOrder() async {
    if (!_form.currentState!.validate()) return;
    final cart = context.read<CartProvider>();
    setState(() => _busy = true);
    try {
      // 1) Create the order (payment status starts as Pending). Prices are checked on the server.
      final orderId = await db.rpc('place_order', params: {
        'p_name': _name.text.trim(),
        'p_phone': _phone.text.trim(),
        'p_address': _address.text.trim(),
        'p_items': cart.items.map((i) => {'food_id': i.food.id, 'qty': i.qty}).toList(),
        'p_payment_method': _paymentMethod,
      }) as int;
                     final total = cart.total;
      cart.clear();

      if (_paymentMethod == 'Cash on Delivery') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentStatusScreen(orderId: orderId, isCashOnDelivery: true),
          ),
        );
        return;
      }

      // Pay online: show the instant QR Ph screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => QrPaymentScreen(orderId: orderId, total: total)),
      );
      return;
    } catch (e) {
      debugPrint('PLACE ORDER ERROR: $e');
      if (mounted) snack(context, 'Error: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Customer Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Delivery address'),
            validator: (v) => (v == null || v.trim().length < 5) ? 'Enter your full address' : null,
          ),
          const SizedBox(height: 20),
          const Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                ...cart.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Expanded(child: Text('${i.qty} × ${i.food.name}')),
                        Text(peso(i.total)),
                      ]),
                    )),
                const Divider(),
                _line('Subtotal', peso(cart.subtotal)),
                _line('Delivery Fee', peso(cart.deliveryFee)),
                _line('Total', peso(cart.total), bold: true),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<String>(
              groupValue: _paymentMethod,
              onChanged: (value) {
                if (!_busy && value != null) setState(() => _paymentMethod = value);
              },
              child: Column(children: [
                RadioListTile<String>(
                  value: 'PayMongo',
                  title: Text('Pay online'),
                  subtitle: Text('QR Ph, GCash, Maya, GrabPay or card'),
                  enabled: !_busy,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<String>(
                  value: 'Cash on Delivery',
                  title: Text('Cash on Delivery'),
                  subtitle: Text('Pay the driver when your order arrives'),
                  enabled: !_busy,
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _placeOrder,
            child: _busy
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_paymentMethod == 'PayMongo' ? 'Place Order & Pay' : 'Place Order'),
          ),
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
