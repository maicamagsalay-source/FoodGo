import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('About Lamón')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.delivery_dining, size: 56, color: primary),
                            const SizedBox(height: 8),
                            Text(
                              'Lamón',
                              style: TextStyle(
                                color: primary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Lamón is a Filipino ordering system created to bring the warmth of '
                        'lutong bahay and lutong Pinoy dishes straight to your table. Built '
                        'with simplicity and convenience in mind, it allows customers to '
                        'browse menus, place orders, and enjoy home-cooked meals without hassle.',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'The name Lamón reflects the joy of eating heartily and celebrating '
                        'Filipino food culture. More than just an ordering tool, Lamón is about '
                        'sharing comfort, tradition, and the taste of home with every meal.',
                      ),
                      const SizedBox(height: 24),
                      const _AboutSection(
                        title: 'Our Mission',
                        content: 'To make Filipino home-cooked meals accessible and easy to '
                            'order, while preserving the authentic flavors of the kitchen.',
                      ),
                      const _AboutSection(
                        title: 'Our Vision',
                        content: 'A community where everyone can enjoy the comfort of lutong '
                            'bahay dishes anytime, anywhere.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Our Values',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const _ValueRow(
                        title: 'Authenticity',
                        content: 'Serving true Filipino flavors.',
                      ),
                      const _ValueRow(
                        title: 'Convenience',
                        content: 'Making ordering simple and reliable.',
                      ),
                      const _ValueRow(
                        title: 'Community',
                        content: 'Bringing people together through food.',
                      ),
                      const _ValueRow(
                        title: 'Joy',
                        content: 'Celebrating the happiness of eating heartily.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final String content;

  const _AboutSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(content),
          ],
        ),
      );
}

class _ValueRow extends StatelessWidget {
  final String title;
  final String content;

  const _ValueRow({required this.title, required this.content});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('•  '),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$title – ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: content),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
