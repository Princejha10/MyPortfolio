import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  /// Stream observing authentication status updates.
  Stream<User?> get authStateChanges;

  /// Logs in a user using Email and Password.
  Future<User?> signInWithEmailAndPassword(String email, String password);

  /// Registers a new user using Email, Password and Name.
  Future<User?> signUpWithEmailAndPassword(String email, String password, String name);

  /// Performs Google Sign-In authentication.
  Future<User?> signInWithGoogle();

  /// Sends a password recovery link to the user's email.
  Future<void> sendPasswordResetEmail(String email);

  /// Signs the current user out.
  Future<void> signOut();

  /// Retrieve the currently authenticated Firebase user.
  User? get currentUser;
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser {
    final user = _firebaseAuth.currentUser;
    debugPrint('[AUTH AUDIT] Current authenticated user query: ${user?.email} (UID: ${user?.uid})');
    return user;
  }

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    debugPrint('[AUTH AUDIT] Step: Executing signInWithEmailAndPassword()');
    debugPrint('[AUTH AUDIT] Param: email = "$email", passwordLength = ${password.length}');
    
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      final user = credential.user;
      debugPrint('[AUTH AUDIT] Firebase success callback triggered for signInWithEmailAndPassword');
      if (user != null) {
        debugPrint('[AUTH AUDIT] Auth Success! User details: Email = ${user.email}, UID = ${user.uid}');
      } else {
        debugPrint('[AUTH AUDIT] Warning: Auth succeeded but returned null User object.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH AUDIT] FirebaseAuthException caught during signInWithEmailAndPassword!');
      debugPrint('[AUTH AUDIT] Code: "${e.code}"');
      debugPrint('[AUTH AUDIT] Message: "${e.message}"');
      throw Exception('[FirebaseAuthException] Code: ${e.code}, Message: ${e.message}');
    } catch (e) {
      debugPrint('[AUTH AUDIT] Unexpected generic Exception caught during signInWithEmailAndPassword: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signUpWithEmailAndPassword(String email, String password, String name) async {
    debugPrint('[AUTH AUDIT] Step: Executing signUpWithEmailAndPassword()');
    debugPrint('[AUTH AUDIT] Param: email = "$email", passwordLength = ${password.length}, name = "$name"');
    
    try {
      debugPrint('[AUTH AUDIT] Calling createUserWithEmailAndPassword() now...');
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      final user = credential.user;
      debugPrint('[AUTH AUDIT] Firebase success callback triggered for createUserWithEmailAndPassword');
      
      if (user != null) {
        debugPrint('[AUTH AUDIT] Auth Success! Registered User UID = ${user.uid}');
        
        debugPrint('[AUTH AUDIT] Current user query immediately after signup: email = ${user.email}, uid = ${user.uid}');
        
        debugPrint('[AUTH AUDIT] Attempting displayName update: "$name"...');
        await user.updateDisplayName(name.trim());
        await user.reload();
        
        final updatedUser = _firebaseAuth.currentUser;
        debugPrint('[AUTH AUDIT] DisplayName update completed. Current user: name = ${updatedUser?.displayName}');
        return updatedUser;
      }
      
      debugPrint('[AUTH AUDIT] Warning: Signup succeeded but returned null User object.');
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH AUDIT] FirebaseAuthException caught during signUpWithEmailAndPassword!');
      debugPrint('[AUTH AUDIT] Code: "${e.code}"');
      debugPrint('[AUTH AUDIT] Message: "${e.message}"');
      throw Exception('[FirebaseAuthException] Code: ${e.code}, Message: ${e.message}');
    } catch (e) {
      debugPrint('[AUTH AUDIT] Unexpected generic Exception caught during signUpWithEmailAndPassword: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    debugPrint('[AUTH AUDIT] Step: Executing signInWithGoogle()');
    try {
      final googleProvider = GoogleAuthProvider();
      debugPrint('[AUTH AUDIT] Triggering signInWithProvider(GoogleAuthProvider)...');
      final credential = await _firebaseAuth.signInWithProvider(googleProvider);
      
      final user = credential.user;
      debugPrint('[AUTH AUDIT] Firebase success callback triggered for signInWithGoogle');
      if (user != null) {
        debugPrint('[AUTH AUDIT] Google Auth Success! Email = ${user.email}, UID = ${user.uid}');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH AUDIT] FirebaseAuthException caught during signInWithGoogle!');
      debugPrint('[AUTH AUDIT] Code: "${e.code}"');
      debugPrint('[AUTH AUDIT] Message: "${e.message}"');
      throw Exception('[FirebaseAuthException] Code: ${e.code}, Message: ${e.message}');
    } catch (e) {
      debugPrint('[AUTH AUDIT] Unexpected generic Exception caught during signInWithGoogle: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('[AUTH AUDIT] Step: Executing sendPasswordResetEmail() for "$email"');
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      debugPrint('[AUTH AUDIT] Firebase password reset call completed successfully.');
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH AUDIT] FirebaseAuthException caught during sendPasswordResetEmail!');
      debugPrint('[AUTH AUDIT] Code: "${e.code}"');
      debugPrint('[AUTH AUDIT] Message: "${e.message}"');
      throw Exception('[FirebaseAuthException] Code: ${e.code}, Message: ${e.message}');
    } catch (e) {
      debugPrint('[AUTH AUDIT] Unexpected generic Exception caught during sendPasswordResetEmail: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    debugPrint('[AUTH AUDIT] Step: Executing signOut() for UID = ${_firebaseAuth.currentUser?.uid}');
    try {
      await _firebaseAuth.signOut();
      debugPrint('[AUTH AUDIT] SignOut completed.');
    } catch (e) {
      debugPrint('[AUTH AUDIT] Error during signOut: $e');
      rethrow;
    }
  }
}
