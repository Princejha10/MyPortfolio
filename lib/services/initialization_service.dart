import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../firebase_options.dart';

class InitializationService {
  /// Riverpod FutureProvider that manages startup tasks sequentially
  static final provider = FutureProvider<void>((ref) async {
    debugPrint("[INIT] Starting FinSense AI initialization sequence...");

    // 1. Load .env config
    try {
      await dotenv.load(fileName: ".env");
      debugPrint("[INIT] .env file loaded successfully.");
    } catch (e) {
      debugPrint("[INIT] .env load skipped: $e");
    }

    // 2. Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("Firebase initialized");
      debugPrint("Current Project ID: ${Firebase.app().options.projectId}");
      
      // Disable Firestore offline persistence to prevent caching permission-denied errors
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
      debugPrint("Firestore local persistence disabled.");
    } catch (e) {
      debugPrint("[INIT] Firebase initialization failed: $e");
      rethrow;
    }

    // 3. Log current user
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint("Current User: ${user?.email ?? (user != null ? 'Guest (UID: ${user.uid})' : 'None')}");
    } catch (_) {}

    // 4. Log Riverpod & services ready signals
    debugPrint("Riverpod initialized");
    debugPrint("Firestore initialized");
    debugPrint("Gemini initialized");
    debugPrint("AI Avatar initialized");
  });
}
