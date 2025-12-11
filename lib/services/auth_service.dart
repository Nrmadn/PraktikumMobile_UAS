import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

// Service untuk autentikasi user (Login & Register)
// - Load users dari users.json (built-in users)
// - Simpan user baru ke SharedPreferences (local storage)

class AuthService {
  static const String _usersKey = 'registered_users';

  // LOAD USERS dari JSON (Built-in Users)
  static Future<List<User>> _loadBuiltInUsers() async {
    try {
      final String response = await rootBundle.loadString('assets/data/users.json');
      final Map<String, dynamic> data = json.decode(response);
      final List<dynamic> usersJson = data['users'] ?? [];
      
      return usersJson.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      print('Error loading built-in users: $e');
      return [];
    }
  }

  // LOAD USERS dari SharedPreferences (Registered Users)
  static Future<List<User>> _loadRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersJson = prefs.getString(_usersKey);
      
      if (usersJson == null || usersJson.isEmpty) {
        return [];
      }

      final List<dynamic> usersList = json.decode(usersJson);
      return usersList.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      print('Error loading registered users: $e');
      return [];
    }
  }

  // GET ALL USERS (Built-in + Registered)
  static Future<List<User>> _getAllUsers() async {
    final builtInUsers = await _loadBuiltInUsers();
    final registeredUsers = await _loadRegisteredUsers();
    
    return [...builtInUsers, ...registeredUsers];
  }

  // SAVE REGISTERED USERS ke SharedPreferences
  static Future<bool> _saveRegisteredUsers(List<User> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String usersJson = json.encode(
        users.map((user) => user.toJson()).toList(),
      );
      
      return await prefs.setString(_usersKey, usersJson);
    } catch (e) {
      print('Error saving registered users: $e');
      return false;
    }
  }

  // CHECK IF EMAIL EXISTS
  static Future<bool> isEmailExists(String email) async {
    final users = await _getAllUsers();
    return users.any((user) => user.email.toLowerCase() == email.toLowerCase());
  }

  // LOGIN - Validate Email & Password
  static Future<User?> login(String email, String password) async {
    try {
      final users = await _getAllUsers();
      
      // Cari user dengan email yang cocok
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => User(
          id: '',
          name: '',
          email: '',
          password: '',
          level: 0,
          points: 0,
          createdAt: DateTime.now(),
        ),
      );

      // Jika user tidak ditemukan
      if (user.id.isEmpty) {
        return null;
      }

      // Validasi password
      if (user.password == password) {
        return user;
      }

      // Password salah
      return null;
    } catch (e) {
      print('Error during login: $e');
      return null;
    }
  }

  //  REGISTER - Create New User (SAVE to Local Storage)
  static Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Check apakah email sudah terdaftar
      final emailExists = await isEmailExists(email);
      if (emailExists) {
        return false; // Email sudah digunakan
      }

      // Generate user ID
      final userId = await generateUserId();

      // Buat user baru
      final newUser = User(
        id: userId,
        name: name,
        email: email,
        password: password,
        level: 1,
        points: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Load existing registered users
      final registeredUsers = await _loadRegisteredUsers();

      // Tambahkan user baru
      registeredUsers.add(newUser);

      // Simpan ke SharedPreferences
      final saved = await _saveRegisteredUsers(registeredUsers);

      if (saved) {
        print('✅ User registered successfully:');
        print('   Name: $name');
        print('   Email: $email');
        print('   ID: $userId');
      }

      return saved;
    } catch (e) {
      print('Error during registration: $e');
      return false;
    }
  }

  // 👤 GET USER BY EMAIL
  static Future<User?> getUserByEmail(String email) async {
    try {
      final users = await _getAllUsers();
      
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => User(
          id: '',
          name: '',
          email: '',
          password: '',
          level: 0,
          points: 0,
          createdAt: DateTime.now(),
        ),
      );

      return user.id.isEmpty ? null : user;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  //  GET ALL USERS (for admin/testing)
  static Future<List<User>> getAllUsers() async {
    return await _getAllUsers();
  }

  //  GET TOTAL USERS COUNT
  static Future<int> getTotalUsersCount() async {
    final users = await _getAllUsers();
    return users.length;
  }

  // GENERATE USER ID (for registration)
  static Future<String> generateUserId() async {
    try {
      // Get total users (built-in + registered)
      final allUsers = await _getAllUsers();
      final totalUsers = allUsers.length;
      
      final newId = totalUsers + 1;
      return 'user_${newId.toString().padLeft(3, '0')}';
    } catch (e) {
      print('Error generating user ID: $e');
      // Fallback: use timestamp
      return 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  //  DELETE ALL REGISTERED USERS (for testing/reset)
  static Future<bool> clearRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_usersKey);
    } catch (e) {
      print('Error clearing registered users: $e');
      return false;
    }
  }

  //  GET REGISTERED USERS COUNT
  static Future<int> getRegisteredUsersCount() async {
    final registeredUsers = await _loadRegisteredUsers();
    return registeredUsers.length;
  }
}
