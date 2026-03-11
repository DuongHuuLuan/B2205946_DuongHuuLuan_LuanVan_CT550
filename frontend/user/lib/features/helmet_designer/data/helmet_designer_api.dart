import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class HelmetDesignerApi {
  Future<Response> getStickerCatalog() async {
    try {
      return await DioClient.instance.get(ApiEndpoints.helmetStickerCatalog);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> generateAiSticker(Map<String, dynamic> body) async {
    try {
      return await DioClient.instance.post(
        ApiEndpoints.helmetStickerGenerate,
        data: body,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> removeBackground(String imageUrl) async {
    try {
      return await DioClient.instance.post(
        ApiEndpoints.helmetStickerRemoveBg,
        data: {"image_url": imageUrl},
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> saveDesign(Map<String, dynamic> body) async {
    try {
      final designId = (body["id"] as num?)?.toInt() ?? 0;
      if (designId > 0) {
        return await DioClient.instance.put(
          ApiEndpoints.helmetDesignDetail(designId),
          data: body,
        );
      }
      return await DioClient.instance.post(
        ApiEndpoints.helmetDesigns,
        data: body,
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> getDesignDetail(int designId) async {
    try {
      return await DioClient.instance.get(
        ApiEndpoints.helmetDesignDetail(designId),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> createShareLink(int designId) async {
    try {
      return await DioClient.instance.post(
        ApiEndpoints.helmetDesignShare(designId),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> orderDesign(int designId) async {
    try {
      return await DioClient.instance.post(
        ApiEndpoints.helmetDesignOrder(designId),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
