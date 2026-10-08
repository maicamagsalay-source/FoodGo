import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'providers.dart';
import 'customer/food_details_screen.dart';

String peso(num v) => '₱${NumberFormat('#,##0.##').format(v)}';
String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
String fmtDate(DateTime d) => DateFormat('MMM d, y • h:mm a').format(d.toLocal());
void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

class FoodImage extends StatelessWidget {
  final String? url;
  final double size;
  final double? height;
  const FoodImage(this.url, {super.key, this.size = 88, this.height});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: height ?? size,
      color: Colors.orange.shade50,
      child: Icon(Icons.fastfood, color: Colors.orange.shade300, size: size * 0.4),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: (url == null || url!.isEmpty)
          ? placeholder
          : Image.network(url!, width: size, height: height ?? size, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  Color get color {
    switch (status) {
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(cap(status),
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      );
}

class FoodCard extends StatelessWidget {
  final Food food;
  const FoodCard(this.food, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => FoodDetailsScreen(food: food))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              FoodImage(food.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(food.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(peso(food.price),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary)),
                        const Spacer(),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 34),
                              padding: const EdgeInsets.symmetric(horizontal: 12)),
                          onPressed: food.isAvailable
                              ? () {
                                  context.read<CartProvider>().add(food);
                                  snack(context, '${food.name} added to cart');
                                }
                              : null,
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(food.isAvailable ? 'Add' : 'Sold out'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorRetry(this.message, this.onRetry, {super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ]),
      );
}
