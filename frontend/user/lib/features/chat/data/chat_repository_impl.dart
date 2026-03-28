import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/data/chat_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_conversation.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_message.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_message_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_read_result.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_repository.dart';
import 'package:dio/dio.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatApi _api;

  ChatRepositoryImpl(this._api);

  @override
  Future<List<ChatConversation>> getConversations() async {
    try {
      final response = await _api.getConversations();
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map(
            (item) =>
                ChatConversation.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ChatConversation> createOrGetConversation({
    int? userId,
    int? adminId,
  }) async {
    try {
      final response = await _api.createOrGetConversation(
        userId: userId,
        adminId: adminId,
      );
      return ChatConversation.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ChatMessagePage> getMessages(
    int conversationId, {
    int? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getMessages(
        conversationId,
        cursor: cursor,
        limit: limit,
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final items = data["items"];
      return ChatMessagePage(
        items: items is List
            ? items
                  .whereType<Map>()
                  .map(
                    (item) =>
                        ChatMessage.fromJson(Map<String, dynamic>.from(item)),
                  )
                  .toList()
            : const [],
        nextCursor: _parseInt(data["next_cursor"]),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ChatMessage> sendMessage(
    int conversationId, {
    String? content,
    String? clientMsgId,
    List<String> filePaths = const [],
  }) async {
    try {
      final response = await _api.sendMessage(
        conversationId,
        content: content,
        clientMsgId: clientMsgId,
        filePaths: filePaths,
      );
      return ChatMessage.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ChatMessage> recallMessage(int conversationId, int messageId) async {
    try {
      final response = await _api.recallMessage(conversationId, messageId);
      return ChatMessage.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ChatReadResult> markConversationRead(
    int conversationId, {
    int? messageId,
  }) async {
    try {
      final response = await _api.markConversationRead(
        conversationId,
        messageId: messageId,
      );
      return ChatReadResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<ChatMessage> addToCartAction(
    int conversationId, {
    required int productDetailId,
    int quantity = 1,
  }) async {
    try {
      final response = await _api.addToCartAction(
        conversationId,
        productDetailId: productDetailId,
        quantity: quantity,
      );
      return ChatMessage.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
