import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/capture_screen.dart';
import 'screens/auth_screen.dart';
import 'config.dart';
import 'screens/preferences/preferences_flow.dart';
import 'services/preferences_service.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Rely on _AuthGate's StreamBuilder for navigation decisions.
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Food Friend',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const AuthScreen();
        }
        // Gate preferences here once, with safe fallback
        return FutureBuilder(
          future: PreferencesService().getMyPreferences(),
          builder: (context, AsyncSnapshot prefsSnap) {
            if (prefsSnap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.orange)),
              );
            }
            // On error, assume no prefs and show onboarding rather than forcing sign-out
            if (prefsSnap.hasError) {
              return const PreferencesFlow();
            }
            final hasPrefs = prefsSnap.data != null;
            return hasPrefs ? const HomeShell() : const PreferencesFlow();
          },
        );
      },
    );
  }
}
