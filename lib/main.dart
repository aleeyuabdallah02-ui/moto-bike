import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'localization/app_localizations.dart';
import 'screens/client_home_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/signup_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp();
  } catch (e, stack) {
    // Show the real error on-screen instead of freezing silently in
    // release mode, which is what was happening before this fix.
    initError = 'Firebase init failed: $e\n\n$stack';
  }

  runApp(initError != null ? ErrorApp(message: initError) : const MotoTaxiApp());
}

/// Shown instead of a frozen screen if Firebase fails to initialize,
/// so we can actually see what's wrong on a real device.
class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
        ),
      ),
    );
  }
}

class MotoTaxiApp extends StatelessWidget {
  const MotoTaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, _, __) {
        return MaterialApp(
          title: 'Moto Taxi Cameroon',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// ONE app, role-based. On launch: if the person already has an
/// anonymous session, look up their stored role and route straight
/// to the Client or Driver home screen. Otherwise show signup with
/// the Client/Driver picker.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }

        final user = authSnapshot.data;
        if (user == null) return const SignupScreen();

        return FutureBuilder<DataSnapshot>(
          future: FirebaseDatabase.instance.ref('users/${user.uid}/role').get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              );
            }

            final role = roleSnapshot.data?.value as String?;
            if (role == 'driver') return const DriverHomeScreen();
            if (role == 'client') return const ClientHomeScreen();

            // No role found (e.g. signup was interrupted) — start over.
            return const SignupScreen();
          },
        );
      },
    );
  }
}
