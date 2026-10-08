import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'providers.dart';
import 'splash_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const LamonApp(),
    ),
  );
}

class LamonApp extends StatelessWidget {
  const LamonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lamón',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
        scaffoldBackgroundColor: const Color(0xFFFAF8F6),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(0, 48),
          ),
        ),
      ),
      home: AppConfig.isSupabaseConfigured ? const SplashScreen() : const _SupabaseSetupScreen(),
    );
  }
}

class _SupabaseSetupScreen extends StatelessWidget {
  const _SupabaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connect Lamón to Supabase',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('Start the app from VS Code and enter your Supabase Project URL '
                    'and anon key when prompted. Find them in Project Settings > API.'),
                SizedBox(height: 12),
                Text('Use only the anon/publishable key in the app. Never use the '
                    'service_role key here.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
