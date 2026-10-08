import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets.dart';
import 'checkout_screen.dart';

class FoodDetailsScreen extends StatefulWidget {
  final Food food;
  const FoodDetailsScreen({super.key, required this.food});
  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final f = widget.food;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Food Details')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          Semantics(
            button: f.imageUrl != null && f.imageUrl!.isNotEmpty,
            label: 'View ${f.name} image full screen',
            child: GestureDetector(
              onTap: f.imageUrl != null && f.imageUrl!.isNotEmpty
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => _FoodImageViewer(food: f),
                          fullscreenDialog: true,
                        ),
                      )
                  : null,
              child: Stack(
                children: [
                  FoodImage(f.imageUrl, size: double.infinity, height: 280),
                  if (f.imageUrl != null && f.imageUrl!.isNotEmpty)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.zoom_in, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _tag(f.isAvailable ? 'Available now' : 'Sold out',
                    f.isAvailable ? Colors.green : colors.error),
                if (f.isFeatured) _tag('Featured', colors.primary),
                if (f.isPopular) _tag('Popular', Colors.deepOrange),
              ]),
              const SizedBox(height: 12),
              Text(f.name, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(peso(f.price),
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.primary)),
              if (f.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(f.description,
                    style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 20),
              const Divider(height: 1),
              _infoRow(Icons.local_shipping_outlined, 'Delivery fee', 'Calculated at checkout'),
              const Divider(height: 1),
              _infoRow(Icons.verified_outlined, 'Availability',
                  f.isAvailable ? 'Ready to add to your order' : 'Currently unavailable'),
              const Divider(height: 1),
              _infoRow(Icons.payments_outlined, 'Payment', 'Online or cash on delivery'),
              const Divider(height: 1),
              const SizedBox(height: 20),
              Row(children: [
                const Expanded(
                  child:
                      Text('Quantity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                IconButton.filledTonal(
                  tooltip: 'Decrease quantity',
                  onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 44,
                  child: Text('$_qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton.filledTonal(
                  tooltip: 'Increase quantity',
                  onPressed: f.isAvailable ? () => setState(() => _qty++) : null,
                  icon: const Icon(Icons.add),
                ),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Item total', style: TextStyle(color: Colors.grey.shade700)),
                Text(peso(f.price * _qty), style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: f.isAvailable
                  ? () {
                      context.read<CartProvider>().add(f, _qty);
                      snack(context, '${f.name} added to cart');
                      Navigator.pop(context);
                    }
                  : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Cart'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: f.isAvailable
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => CartProvider()..add(f, _qty),
                            child: const CheckoutScreen(),
                          ),
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('Buy Now'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child:
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      );

  Widget _infoRow(IconData icon, String title, String detail) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(children: [
          Icon(icon, size: 21, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          SizedBox(
              width: 100, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(detail, style: TextStyle(color: Colors.grey.shade700))),
        ]),
      );
}

class _FoodImageViewer extends StatefulWidget {
  final Food food;
  const _FoodImageViewer({required this.food});

  @override
  State<_FoodImageViewer> createState() => _FoodImageViewerState();
}

class _FoodImageViewerState extends State<_FoodImageViewer> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomBy(double factor) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final nextScale = (scale * factor).clamp(1.0, 5.0);
    _transformationController.value = Matrix4.identity()
      ..scaleByDouble(nextScale, nextScale, nextScale, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.food.name),
        actions: [
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: () => _transformationController.value = Matrix4.identity(),
            icon: const Icon(Icons.fit_screen),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1,
              maxScale: 5,
              child: Image.network(
                widget.food.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 64,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pinch to zoom',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Zoom out',
                      onPressed: () => _zoomBy(0.8),
                      icon: const Icon(Icons.zoom_out),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      tooltip: 'Zoom in',
                      onPressed: () => _zoomBy(1.25),
                      icon: const Icon(Icons.zoom_in),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
