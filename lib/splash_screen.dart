import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'auth_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await context.read<AuthProvider>().loadProfile();
    if (!mounted) return;
    goToLanding(context);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: primary,
      body: Center(
        child: FadeTransition(
          opacity: _c,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(Icons.delivery_dining, size: 64, color: primary),
                ),
                const SizedBox(height: 16),
                const Text('Lamón',
                    style:
                        TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('Filipino Cuisine', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
