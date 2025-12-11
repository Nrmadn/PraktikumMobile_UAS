import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/user_model.dart';

class FirebaseAuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  static CollectionReference get _usersCollection => _firestore.collection('users');

  /// ✅ REGISTER - FIXED VERSION
  static Future<User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ⚠️ TUNGGU SEBENTAR UNTUK AVOID RACE CONDITION
      await Future.delayed(const Duration(milliseconds: 500));

      if (credential.user == null) return null;

      // 2. Create user document in Firestore
      final newUser = User(
        id: credential.user!.uid,
        name: name,
        email: email,
        password: '', // Don't store password!
        level: 1,
        points: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _usersCollection.doc(newUser.id).set(newUser.toJson());

      print('✅ User registered: $email');
      return newUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'weak-password') {
        print('❌ The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('❌ The account already exists for that email.');
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ Registration error: $e');
      print('❌ StackTrace: $stackTrace');
      return null;
    }
  }

  /// ✅ LOGIN - FIXED VERSION
  static Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ⚠️ TUNGGU SEBENTAR
      await Future.delayed(const Duration(milliseconds: 500));

      if (credential.user == null) return null;

      final doc = await _usersCollection.doc(credential.user!.uid).get();
      
      if (!doc.exists) {
        print('❌ User document not found in Firestore');
        return null;
      }

      return User.fromJson(doc.data() as Map<String, dynamic>);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        print('❌ No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('❌ Wrong password provided.');
      } else if (e.code == 'invalid-credential') {
        print('❌ Invalid email or password.');
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ Login error: $e');
      print('❌ StackTrace: $stackTrace');
      return null;
    }
  }

  /// ✅ LOGOUT
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// ✅ GET CURRENT USER
  static Future<User?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final doc = await _usersCollection.doc(currentUser.uid).get();
      if (!doc.exists) return null;

      return User.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      print('❌ Get current user error: $e');
      return null;
    }
  }

  /// ✅ CHECK IF EMAIL EXISTS
  static Future<bool> isEmailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// ✅ GET USER ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}