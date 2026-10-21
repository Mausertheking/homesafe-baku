import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase_bootstrap.dart';
import '../../core/settings.dart';

/// Signed-in user, or null (signed out, guest, or Firebase unavailable).
final authStateProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseAvailableProvider)) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) => ref.watch(authStateProvider).value);

/// True once we KNOW whether someone is signed in: Firebase has started (or
/// failed, meaning offline-only) and the saved login has been restored.
/// Until then the router must not send anyone to the sign-in screen,
/// otherwise signed-in users see it flash at every app start.
final authResolvedProvider = Provider<bool>((ref) {
  final ready = ref.watch(firebaseReadyProvider);
  if (!ready.hasValue) return false;
  if (ready.value != true) return true;
  final auth = ref.watch(authStateProvider);
  return auth.hasValue && !auth.isLoading;
});

enum AuthError { invalidEmail, emailOrPassword, emailInUse, weakPassword, unavailable, other }

class AuthException implements Exception {
  AuthException(this.error);
  final AuthError error;
}

/// Email + password only (phone sign-in was removed on request).
class AuthService {
  AuthService(this._ref);
  final Ref _ref;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  FirebaseAuth get _auth {
    if (!_ref.read(firebaseAvailableProvider)) throw AuthException(AuthError.unavailable);
    return FirebaseAuth.instance;
  }

  String _checkEmail(String email) {
    final e = email.trim();
    if (!_emailPattern.hasMatch(e)) throw AuthException(AuthError.invalidEmail);
    return e;
  }

  static AuthError _map(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => AuthError.invalidEmail,
        'email-already-in-use' => AuthError.emailInUse,
        'weak-password' => AuthError.weakPassword,
        'network-request-failed' => AuthError.unavailable,
        _ => AuthError.emailOrPassword,
      };

  Future<void> signInWithEmail(String email, String password) async {
    final e = _checkEmail(email);
    try {
      await _auth.signInWithEmailAndPassword(email: e, password: password);
      await _afterSignIn();
    } on FirebaseAuthException catch (err) {
      throw AuthException(_map(err));
    }
  }

  Future<void> createEmailAccount(String email, String password) async {
    final e = _checkEmail(email);
    if (password.length < 8) throw AuthException(AuthError.weakPassword);
    try {
      await _auth.createUserWithEmailAndPassword(email: e, password: password);
      await _afterSignIn();
    } on FirebaseAuthException catch (err) {
      throw AuthException(_map(err));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final e = _checkEmail(email);
    try {
      await _auth.sendPasswordResetEmail(email: e);
    } on FirebaseAuthException catch (err) {
      // Do not reveal whether an account exists for this email.
      if (err.code == 'invalid-email') throw AuthException(AuthError.invalidEmail);
    }
  }

  Future<void> signOut() async {
    if (_ref.read(firebaseAvailableProvider)) await FirebaseAuth.instance.signOut();
  }

  /// Creates users/{uid} on first sign-in and keeps the language in sync.
  Future<void> _afterSignIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _ref.read(settingsProvider.notifier).setGuestMode(false);
    final doc = FirebaseFirestore.instance.doc('users/${user.uid}');
    final language = _ref.read(settingsProvider).language;
    final snapshot = await doc.get();
    if (snapshot.exists) {
      await doc.update({'language': language});
    } else {
      await doc.set({'language': language, 'createdAt': FieldValue.serverTimestamp()});
    }
  }
}

final authServiceProvider = Provider<AuthService>(AuthService.new);
