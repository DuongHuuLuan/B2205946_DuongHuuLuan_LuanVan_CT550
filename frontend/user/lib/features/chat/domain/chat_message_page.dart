import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_message.dart';

class ChatMessagePage {
  final List<ChatMessage> items;
  final int? nextCursor;

  const ChatMessagePage({
    required this.items,
    required this.nextCursor,
  });
}
