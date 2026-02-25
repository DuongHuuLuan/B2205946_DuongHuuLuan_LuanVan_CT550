import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class ProfileApi {
  Future<Response> getProfile() async {
    try {
      return await DioClient.instance.get(ApiEndpoints.profileMe);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> updateProfile(Map<String, dynamic> data) async {
    try {
      return await DioClient.instance.put(ApiEndpoints.profileMe, data: data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> uploadAvatar({
    required String filePath,
    String? fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });
      return await DioClient.instance.post(
        ApiEndpoints.profileMeAvatar,
        data: formData,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
