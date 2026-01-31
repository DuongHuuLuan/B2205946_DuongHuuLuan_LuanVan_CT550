import 'package:dio/dio.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/data/models/profile_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/data/profile_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/domain/profile.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApi _api;
  ProfileRepositoryImpl(this._api);

  @override
  Future<Profile> getProfile() async {
    try {
      final response = await _api.getProfile();

      return ProfileMapper.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Profile> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.updateProfile(data);

      return ProfileMapper.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
