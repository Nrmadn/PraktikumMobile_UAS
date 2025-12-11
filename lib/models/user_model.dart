// =====================================================
// 👤 USER MODEL
// =====================================================
// Model ini mendefinisikan struktur data untuk User
// Digunakan untuk: Login, Register, Profile, dll

class User {
  String id;
  String name;
  String email;
  String password;
  int level;
  int points;
  DateTime createdAt;
  DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.level,
    required this.points,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert dari JSON (dari API/Database) ke Object User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      level: json['level'] ?? 1,
      points: json['points'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Convert dari Object User ke JSON (untuk API/Database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'level': level,
      'points': points,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Copy With - untuk membuat copy dengan beberapa field berubah
  // Berguna untuk state management
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    int? level,
    int? points,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      level: level ?? this.level,
      points: points ?? this.points,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Override toString untuk debugging
  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, level: $level, points: $points)';
  }

  // Override == dan hashCode untuk perbandingan object
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}