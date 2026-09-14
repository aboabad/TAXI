import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Getters لبيانات المستخدم الحالي للتوافق مع جميع الشاشات
  User? get currentUser => _auth.currentUser;
  User? get user => _auth.currentUser;

  // ✅ دالة تسجيل الدخول (signIn)
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // نجح التسجيل بدون أخطاء
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'حدث خطأ أثناء تسجيل الدخول';
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  // ✅ دالة إنشاء حساب جديد (signUp) - تدعم التمرير المباشر والمسمى لتفادي أخطاء signup_screen
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
        password: password.trim(),
      );

      final user = credential.user;
      if (user != null) {
        final displayName = (name != null && name.isNotEmpty)
            ? name
            : email.split('@').first;

        // تحديث الاسم في FirebaseAuth
        await user.updateDisplayName(displayName);

        // إنشاء مستند المستخدم في Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': displayName,
          'email': email.trim(),
          'phone': phone ?? '',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null; // نجح إنشاء الحساب
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'حدث خطأ أثناء إنشاء الحساب';
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  // ✅ دالة جلب صلاحية المستخدم (getUserRole)
  Future<String> getUserRole(String uid) async {
    // 💡 فحص مباشر للحساب الإداري للتأكد من الدخول كـ Admin فوراً
    final email = currentUser?.email?.toLowerCase().trim();
    if (email == 'aboabad1990@gmail.com' || email == 'aboobad1990@gmail.com') {
      return 'admin';
    }

    try {
      // 1. البحث باستخدام الـ UID
      DocumentSnapshot doc =
      await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('role') && data['role'] != null) {
          return data['role'].toString().trim().toLowerCase();
        }
      }

      // 2. البحث ببريد المستخدم إذا لم يجد الـ UID
      if (email != null) {
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          return data['role']?.toString().trim().toLowerCase() ?? 'user';
        }
      }

      return 'user';
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return 'user';
    }
  }

  // ✅ دالة تسجيل الخروج (signOut)
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}