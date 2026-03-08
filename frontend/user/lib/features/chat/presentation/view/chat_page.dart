import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/domain/chat_message.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/presentation/viewmodel/chat_viewmodel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ChatViewmodel>().openSupportConversation();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<ChatViewmodel>().leaveConversation();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (!mounted || files.isEmpty) return;
    setState(() {
      _selectedImages
        ..clear()
        ..addAll(files.map((file) => file.path));
    });
  }

  Future<void> _send(ChatViewmodel vm) async {
    final content = _messageController.text.trim();
    final images = List<String>.from(_selectedImages);
    if (content.isEmpty && images.isEmpty) return;

    try {
      await vm.sendMessage(content: content, filePaths: images);
      if (!mounted) return;
      _messageController.clear();
      setState(_selectedImages.clear);
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      // Chuyển đổi thông báo lỗi sang tiếng Việt
      final message = vm.errorMessage ?? "Không thể gửi tin nhắn.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewmodel>();
    final vm = context.watch<ChatViewmodel>();
    final myUserId = auth.user?.id ?? 0;
    final messages = vm.messages;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Liên hệ hỗ trợ"),
            Text(
              vm.isSocketConnected
                  ? "Đã kết nối trực tuyến"
                  : "Đang đồng bộ...",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: vm.isOpeningConversation || vm.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(
                    child: Text(
                      "Chưa có tin nhắn nào. Hãy bắt đầu cuộc trò chuyện.",
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.userId == myUserId;
                      final isRead =
                          isMine &&
                          vm.counterpartLastReadMessageId != null &&
                          message.id <= vm.counterpartLastReadMessageId!;
                      return _ChatBubble(
                        message: message,
                        isMine: isMine,
                        isRead: isRead,
                      );
                    },
                  ),
          ),
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 92,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final path = _selectedImages[index];
                  return Container(
                    width: 128,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.image_outlined, size: 18),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          path.split("\\").last.split("/").last,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _selectedImages.length,
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: vm.isSending ? null : _pickImages,
                    icon: const Icon(Icons.image_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: "Nhập tin nhắn...",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: vm.isSending ? null : () => _send(vm),
                    child: vm.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool isRead;

  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.isRead,
  });

  bool get _isImageOnly =>
      message.mediaItems.isNotEmpty &&
      message.mediaItems.every((item) => item.mediaType == "image");

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final textColor = isMine ? scheme.onPrimary : scheme.onSurface;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.74,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: align,
            children: [
              if (message.mediaItems.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.mediaItems.map((item) {
                    if (_isImageOnly) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: item.path,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 150,
                            height: 150,
                            color: Colors.black12,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.path.split("/").last,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              if (message.mediaItems.isNotEmpty &&
                  (message.content?.isNotEmpty ?? false))
                const SizedBox(height: 8),
              if (message.content != null && message.content!.trim().isNotEmpty)
                Text(message.content!, style: TextStyle(color: textColor)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, bottom: 8),
          child: Text(
            isRead ? "Đã xem" : _formatTime(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return "";
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, "0");
    final minute = local.minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }
}
