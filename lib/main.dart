// ============================================================================
// FIREBASE IMPORTS - COMMENTED OUT FOR API MIGRATION
// Uncomment these imports when scaling back to Firebase
// ============================================================================
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'services/auth_service.dart';
// import 'services/firestore_service.dart';
// ============================================================================
import 'dart:js' if (dart.library.html) 'dart:js';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'config/environment.dart';
import 'screens/auth_screen.dart';
import 'screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration from .env file
  await Environment.initialize();
  
  // Expose Google Maps API key to JavaScript for web
  if (kIsWeb) {
    _setGoogleMapsApiKey();
  }
  
  // ============================================================================
// FIREBASE INITIALIZATION - COMMENTED OUT FOR API MIGRATION
// Uncomment this line when scaling back to Firebase
// ============================================================================
// await FirestoreService().initializeFirebase();
// ============================================================================
  
  // API Service initializes automatically via singleton pattern
  // No explicit initialization needed
  
  if (!kIsWeb) {
    await NotificationService().initialize();
  }
  runApp(const MyApp());
}

/// Exposes the Google Maps API key to JavaScript global variable
/// This allows index.html to read the key and load the Maps API
void _setGoogleMapsApiKey() {
  final apiKey = Environment.googleMapsApiKey;
  if (apiKey.isNotEmpty) {
    final script = web.window.document.createElement('script');
    script.text = 'window.googleMapsApiKey = "$apiKey";';
    web.window.document.head!.appendChild(script);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motorbike Parking App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // ============================================================================
    // FIREBASE AUTH STREAM - COMMENTED OUT FOR API MIGRATION
    // Uncomment this StreamBuilder when scaling back to Firebase
    // ============================================================================
    /*
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const MapScreen();
        }
        return const AuthScreen();
      },
    );
    */
    // ============================================================================
    
    // API-based authentication: Check for stored JWT token
    return FutureBuilder<String?>(
      future: ApiService().getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MapScreen();
        }
        return const AuthScreen();
      },
    );
  }
}

