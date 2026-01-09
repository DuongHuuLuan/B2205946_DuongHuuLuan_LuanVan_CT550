import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/user.dart';

class UserMapper extends User {
  UserMapper({
    required super.id,
    required super.email,
    required super.username,
    required super.role,
  });

  factory UserMapper.fromJson(Map<String, dynamic> json) {
    return UserMapper(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "email": email, "username": username, "role": role};
  }
}

