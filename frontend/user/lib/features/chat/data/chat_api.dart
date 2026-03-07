import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:dio/dio.dart';

class ChatApi {
  Future<Response> getConversations() async {
    try {
      return await DioClient.instance.get(ApiEndpoints.chatConversations);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> createOrGetConversation({
    int? userId,
    int? adminId,
  }) async {
    try {
      return await DioClient.instance.post(
        ApiEndpoints.chatConversations,
        data: {
          "user_id": userId,
          "admin_id": adminId,
        },
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> getMessages(
    int conversationId, {
    int? cursor,
    int limit = 20,
  }) async {
    try {
      return await DioClient.instance.get(
        ApiEndpoints.chatMessages(conversationId),
        queryParameters: {
          "cursor": cursor,
          "limit": limit,
        }..removeWhere((key, value) => value == null),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> sendMessage(
    int conversationId, {
    String? content,
    String? clientMsgId,
    List<String> filePaths = const [],
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (content != null && content.trim().isNotEmpty) {
        payload["content"] = content.trim();
      }
      if (clientMsgId != null && clientMsgId.isNotEmpty) {
        payload["client_msg_id"] = clientMsgId;
      }
      if (filePaths.isNotEmpty) {
        payload["files"] = await Future.wait(
          filePaths.map((path) => MultipartFile.fromFile(path)),
        );
      }
      return await DioClient.instance.post(
        ApiEndpoints.chatMessages(conversationId),
        data: FormData.fromMap(payload),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  Future<Response> markConversationRead(
    int conversationId, {
    int? messageId,
  }) async {
    try {
      return await DioClient.instance.post(
        ApiEndpoints.chatRead(conversationId),
        data: {
          "message_id": messageId,
        }..removeWhere((key, value) => value == null),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
