import 'package:b2205946_duonghuuluan_luanvan/app/utils/json_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/domain/profile.dart';

class ProfileMapper {
  static Profile fromJson(Map<String, dynamic> json) {
    return Profile(
      id: (json["id"] as Object?).toInt(),
      userId: (json["user_id"] as Object?).toInt(),
      name: json["name"]?.toString(),
      phone: json["phone"]?.toString(),
      gender: json["gender"]?.toString(),
      birthday: (json["birthday"] as Object?).toDateTime(),
      avatar: json["avatar"]?.toString(),
    );
  }
}
