import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  User? get user => _auth.currentUser;

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'حدث خطأ أثناء تسجيل الدخول';
    } catch (_) {
      return 'حدث خطأ غير متوقع';
    }
  }

  Future<String?> signUp(
    String email,
    String password, {
    String? name,
    String? phone,
    String role = 'user',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final newUser = credential.user;
      if (newUser != null) {
        final displayName = (name != null && name.trim().isNotEmpty)
            ? name.trim()
            : email.split('@').first;

        await newUser.updateDisplayName(displayName);
        await _firestore.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'name': displayName,
          'email': email.trim().toLowerCase(),
          'phone': phone?.trim() ?? '',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'حدث خطأ أثناء إنشاء الحساب';
    } catch (_) {
      return 'حدث خطأ غير متوقع';
    }
  }

  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return 'user';

      final role = doc.data()?['role']?.toString().trim().toLowerCase();
      if (role == null || role.isEmpty) return 'user';
      return role;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return 'user';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
