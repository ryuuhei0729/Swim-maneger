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
    try {
      // 必須フィールドの存在チェック
      if (!json.containsKey('id') || json['id'] == null) {
        throw FormatException('User.fromJson: required field "id" is missing or null');
      }
      if (!json.containsKey('email') || json['email'] == null) {
        throw FormatException('User.fromJson: required field "email" is missing or null');
      }
      if (!json.containsKey('name') || json['name'] == null) {
        throw FormatException('User.fromJson: required field "name" is missing or null');
      }
      if (!json.containsKey('user_type') || json['user_type'] == null) {
        throw FormatException('User.fromJson: required field "user_type" is missing or null');
      }

      // 型チェックとキャスト
      final id = json['id'];
      if (id is! int) {
        throw FormatException('User.fromJson: field "id" must be an integer, got ${id.runtimeType}');
      }

      final email = json['email'];
      if (email is! String) {
        throw FormatException('User.fromJson: field "email" must be a string, got ${email.runtimeType}');
      }

      final name = json['name'];
      if (name is! String) {
        throw FormatException('User.fromJson: field "name" must be a string, got ${name.runtimeType}');
      }

      final userType = json['user_type'];
      if (userType is! int) {
        throw FormatException('User.fromJson: field "user_type" must be an integer, got ${userType.runtimeType}');
      }

      // オプショナルフィールドの安全な処理
      final avatar = json['avatar'] as String?;

      // 日付フィールドの安全なパース
      DateTime? createdAt;
      if (json['created_at'] != null) {
        try {
          createdAt = DateTime.parse(json['created_at'].toString());
        } catch (e) {
          // 日付パースエラーは警告として記録し、nullとして扱う
          // 日付パースエラーは警告として記録し、nullとして扱う
        }
      }

      DateTime? updatedAt;
      if (json['updated_at'] != null) {
        try {
          updatedAt = DateTime.parse(json['updated_at'].toString());
        } catch (e) {
          // 日付パースエラーは警告として記録し、nullとして扱う
          // 日付パースエラーは警告として記録し、nullとして扱う
        }
      }

      return User(
        id: id,
        email: email,
        name: name,
        avatar: avatar,
        userType: userType,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      // 既存のFormatExceptionはそのまま再スロー
      if (e is FormatException) {
        rethrow;
      }
      // その他のエラーはFormatExceptionとしてラップ
      throw FormatException('User.fromJson: unexpected error: $e');
    }
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
