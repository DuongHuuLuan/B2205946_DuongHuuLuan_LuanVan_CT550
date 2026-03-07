import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_conversation.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_message.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_message_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_read_result.dart';

abstract class ChatRepository {
  Future<List<ChatConversation>> getConversations();

  Future<ChatConversation> createOrGetConversation({
    int? userId,
    int? adminId,
  });

  Future<ChatMessagePage> getMessages(
    int conversationId, {
    int? cursor,
    int limit = 20,
  });

  Future<ChatMessage> sendMessage(
    int conversationId, {
    String? content,
    String? clientMsgId,
    List<String> filePaths = const [],
  });

  Future<ChatReadResult> markConversationRead(
    int conversationId, {
    int? messageId,
  });
}
