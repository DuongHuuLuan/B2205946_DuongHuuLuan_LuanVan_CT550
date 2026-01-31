import 'package:b2205946_duonghuuluan_luanvan/features/profile/domain/profile.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile();
  Future<Profile> updateProfile(Map<String, dynamic> data);
}
