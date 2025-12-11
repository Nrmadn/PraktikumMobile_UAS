// Digunakan untuk: CRUD Target, Home Screen, Progress, dll
// UPDATE: Menambahkan targetDate untuk tanggal target

class TargetIbadah {
  String id;
  String userId;
  String name;
  String category; // Sholat, Qur'an, Sedekah, Dzikir.
  String note;
  bool isCompleted;
  DateTime targetDate; // TANGGAL TARGET
  DateTime createdAt;
  DateTime? completedAt;
  DateTime updatedAt;

  TargetIbadah({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.note,
    required this.isCompleted,
    required this.targetDate, // 🆕
    required this.createdAt,
    this.completedAt,
    required this.updatedAt,
  });

  // Convert dari JSON (dari API/Database) ke Object TargetIbadah
  factory TargetIbadah.fromJson(Map<String, dynamic> json) {
    return TargetIbadah(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Lainnya',
      note: json['note'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // Convert dari Object TargetIbadah ke JSON (untuk API/Database)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'category': category,
      'note': note,
      'isCompleted': isCompleted,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy With - untuk membuat copy dengan beberapa field berubah
  TargetIbadah copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? note,
    bool? isCompleted,
    DateTime? targetDate,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return TargetIbadah(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
      targetDate: targetDate ?? this.targetDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 🆕 Helper: Cek apakah target untuk hari ini
  bool isForToday() {
    final now = DateTime.now();
    return targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;
  }

  // 🆕 Helper: Cek apakah target sudah lewat
  bool isOverdue() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.isBefore(today) && !isCompleted;
  }

  // 🆕 Helper: Format tanggal target
  String getFormattedDate() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${targetDate.day} ${months[targetDate.month - 1]} ${targetDate.year}';
  }

  // Override toString untuk debugging
  @override
  String toString() {
    return 'TargetIbadah(id: $id, name: $name, category: $category, targetDate: ${getFormattedDate()}, isCompleted: $isCompleted)';
  }

  // Override == dan hashCode untuk perbandingan object
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetIbadah &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode;
}