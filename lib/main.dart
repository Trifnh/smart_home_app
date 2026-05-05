import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerWidget, ProviderScope, WidgetRef;

import 'demo/ui_demo_config.dart';
import 'firebase_options.dart';
import 'providers/mqtt_providers.dart';
import 'providers/theme_providers.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/firebase_service.dart';
import 'services/mqtt_edge_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;

  if (kUiDemoMode) {
    FirebaseService.activateUiDemo();
    await MqttEdgeService.instance.loadPrefs();
  } else {
    try {
      if (!DefaultFirebaseOptions.isConfigured) {
        throw Exception(
          'Firebase is not configured yet. Run "flutterfire configure" to generate a real '
          'firebase_options.dart, then restart the app.',
        );
      }
      await FirebaseService.instance.initFirebase(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await MqttEdgeService.instance.loadPrefs();
    } catch (e) {
      initError = e.toString();
    }
  }

  runApp(
    ProviderScope(
      child: MyApp(initError: initError, uiDemo: kUiDemoMode),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key, this.initError, this.uiDemo = false});

  final String? initError;
  final bool uiDemo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Ensure singleton services are "touched" so listeners can rebuild UI.
    ref.watch(mqttEdgeServiceProvider);
    if (initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart AIoT Home',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: _InitErrorScreen(message: initError!),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart AIoT Home',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      builder: (context, child) {
        if (!uiDemo || child == null) return child ?? const SizedBox.shrink();
        return Banner(
          message: 'MOCK',
          location: BannerLocation.topEnd,
          color: const Color(0xFFE65100),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          child: child,
        );
      },
      home: _AuthSwitcher(uiDemo: uiDemo),
    );
  }
}

/// Chooses Shell when signed in — no manual route push after Login.
class _AuthSwitcher extends StatelessWidget {
  const _AuthSwitcher({this.uiDemo = false});

  final bool uiDemo;

  @override
  Widget build(BuildContext context) {
    if (uiDemo) {
      return const ShellScreen();
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.accent.withValues(alpha: 0.85),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          return const ShellScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class _InitErrorScreen extends StatelessWidget {
  const _InitErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Firebase initialization failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
