import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../widgets.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final VoidCallback onBrowse;
  const CartScreen({super.key, required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          const Text('Your cart is empty', style: TextStyle(fontSize: 18)),
          TextButton(onPressed: onBrowse, child: const Text('Browse food')),
        ]),
      );
    }
    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Align(
            alignment: Alignment.centerLeft,
            child: Text('My Cart', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: cart.items.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  FoodImage(item.food.imageUrl, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(peso(item.food.price)),
                      Row(children: [
                        IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => cart.decrease(item.food.id),
                            icon: const Icon(Icons.remove_circle_outline)),
                        Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => cart.increase(item.food.id),
                            icon: const Icon(Icons.add_circle_outline)),
                      ]),
                    ]),
                  ),
                  Column(children: [
                    IconButton(
                        onPressed: () => cart.remove(item.food.id),
                        icon: const Icon(Icons.delete_outline, color: Colors.red)),
                    Text(peso(item.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)]),
        child: Column(children: [
          _row('Subtotal', peso(cart.subtotal)),
          _row('Delivery Fee', peso(cart.deliveryFee)),
          const Divider(),
          _row('Total', peso(cart.total), bold: true),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _row(String l, String v, {bool bold = false}) {
    final style = TextStyle(fontSize: bold ? 18 : 15, fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: style), Text(v, style: style)]),
    );
  }
}
