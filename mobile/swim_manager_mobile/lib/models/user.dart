class User {
  final int id;
  final String email;
  final String name;
  final String? avatar;
  final int userType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.userType,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      avatar: json['avatar'],
      userType: json['user_type'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'user_type': userType,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ユーザータイプの判定メソッド
  bool get isPlayer => userType == 0;
  bool get isManager => userType == 1;
  bool get isCoach => userType == 2;
  bool get isDirector => userType == 3;

  // ユーザータイプの文字列表現
  String get userTypeString {
    switch (userType) {
      case 0:
        return '選手';
      case 1:
        return 'マネージャー';
      case 2:
        return 'コーチ';
      case 3:
        return '監督';
      default:
        return '不明';
    }
  }

  // 管理者権限の判定
  bool get isAdmin => userType >= 1;
  bool get isCoachOrHigher => userType >= 2;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, userType: $userTypeString)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
