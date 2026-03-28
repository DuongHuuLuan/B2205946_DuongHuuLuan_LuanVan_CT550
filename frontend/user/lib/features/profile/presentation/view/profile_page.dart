import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/app/widgets/app_logo_loader.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/chat/presentation/viewmodel/chat_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/presentation/viewmodel/evaluate_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/viewmodel/profile_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/profile_header.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/profile_utility_grid.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/profile_edit_dialog.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/quick_order_grid.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();

  // @override
  // void initState() {
  //   super.initState();
  //   context.read<ProfileViewmodel>().load();
  //   context.read<EvaluateViewmodel>().load(perPage: 10);
  //   context.read<ChatViewmodel>().loadConversations(silent: true);
  // }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ProfileViewmodel>().load();

      if (!mounted) return;
      final vm = context.read<ProfileViewmodel>();
      final evaluateVm = context.read<EvaluateViewmodel>();

      if (vm.completedOrders.isNotEmpty) {
        final orderIds = vm.completedOrders.map((e) => e.id).toList();
        await evaluateVm.syncEvaluateStatusForOrders(orderIds);
      }

      await evaluateVm.load(perPage: 10);
      context.read<ChatViewmodel>().loadConversations(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewmodel>();
    final vm = context.watch<ProfileViewmodel>();
    final evaluateVm = context.watch<EvaluateViewmodel>();
    final chatVm = context.watch<ChatViewmodel>();
    final profile = vm.profile;
    final completedOrders = vm.completedOrders;

    // _scheduleEvaluateStatusSync(completedOrders, evaluateVm);

    final pendingReviewCount = completedOrders
        .where((order) => !evaluateVm.reviewedOrderIds.contains(order.id))
        .length;

    final utilities = [
      ProfileUtilityItem(
        icon: Icons.rate_review_outlined,
        accentColor: Colors.black54,
        title: "Lịch sử đánh giá",
        subtitle: evaluateVm.total > 0
            ? "${evaluateVm.total} đánh giá đã gửi"
            : "Xem các nhận xét bạn đã tạo",
        onTap: () => context.push("/profile/reviews"),
      ),
      ProfileUtilityItem(
        icon: Icons.confirmation_number_outlined,
        accentColor: Colors.black45,
        title: "Kho voucher",
        subtitle: vm.availableDiscounts.isEmpty
            ? "Chưa có mã khả dụng"
            : "${vm.availableDiscounts.length} mã đang dùng được",
        onTap: () => context.push("/profile/vouchers"),
      ),
      ProfileUtilityItem(
        icon: Icons.badge_outlined,
        accentColor: Colors.black54,
        title: "Chỉnh sửa hồ sơ",
        subtitle: "Cập nhật tên, ảnh đại diện và thông tin liên hệ",
        onTap: vm.isUpdatingProfile ? null : () => _openEditProfileDialog(auth),
      ),
      ProfileUtilityItem(
        icon: Icons.chat_bubble_outline,
        accentColor: Colors.black54,
        title: "Trò chuyện",
        subtitle: chatVm.unreadTotal > 0
            ? "Bạn có tin nhắn chưa đọc từ shop"
            : "Liên hệ shop khi cần hỗ trợ",
        badgeText: chatVm.unreadTotal > 0
            ? (chatVm.unreadTotal > 99 ? "99+" : "${chatVm.unreadTotal}")
            : null,
        onTap: () => context.push("/chat"),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: AppBar(
        // backgroundColor: const Color(0xFFF2593A),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text("Tài khoản"),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/");
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: "Trò chuyện",
            onPressed: () async {
              final chatViewmodel = context.read<ChatViewmodel>();
              await context.push("/chat");
              if (!mounted) return;
              await chatViewmodel.loadConversations(silent: true);
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline),
                if (chatVm.unreadTotal > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        chatVm.unreadTotal > 99
                            ? "99+"
                            : "${chatVm.unreadTotal}",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Làm mới",
            onPressed: vm.isLoading ? null : _refreshAll,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: "Đăng xuất",
            onPressed: auth.isAuthenticated ? () => _confirmLogout(auth) : null,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: vm.isLoading && profile == null && vm.orders.isEmpty
          ? const Center(child: AppLogoLoader(size: 80, strokeWidth: 4))
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHeader(
                      name: _pickName(vm.profile?.name, auth.user?.username),
                      email: auth.user?.email ?? "Chưa có email",
                      avatarUrl: _resolveAvatar(vm.profile?.avatar),
                      supportingText: _supportingText(vm),
                      stats: [
                        ProfileHeaderStat(
                          label: "Đơn đã mua",
                          value: "${vm.orders.length}",
                        ),
                        ProfileHeaderStat(
                          label: "Chờ đánh giá",
                          value: "$pendingReviewCount",
                        ),
                        ProfileHeaderStat(
                          label: "Voucher",
                          value: "${vm.availableDiscounts.length}",
                        ),
                      ],
                      onEditPressed: vm.isUpdatingProfile
                          ? null
                          : () => _openEditProfileDialog(auth),
                    ),
                    const SizedBox(height: 18),
                    _SectionShell(
                      title: "Đơn mua",
                      actionLabel: "Xem lịch sử mua hàng",
                      onActionTap: () => context.push("/profile/orders"),
                      child: QuickOrderGrid(
                        items: [
                          QuickOrderItem(
                            icon: Icons.pending_actions_outlined,
                            label: "Chờ xác nhận",
                            count: vm.pendingCount,
                            color: Colors.black54,
                            onTap: () =>
                                context.push("/profile/orders?tab=pending"),
                          ),
                          QuickOrderItem(
                            icon: Icons.local_shipping_outlined,
                            label: "Đang giao",
                            count: vm.shippingCount,
                            color: Colors.black54,
                            onTap: () =>
                                context.push("/profile/orders?tab=shipping"),
                          ),
                          QuickOrderItem(
                            icon: Icons.inventory_2_outlined,
                            label: "Đã giao",
                            count: vm.completedCount,
                            color: Colors.black54,
                            onTap: () =>
                                context.push("/profile/orders?tab=completed"),
                          ),
                          QuickOrderItem(
                            icon: Icons.star_outline_rounded,
                            label: "Đánh giá",
                            count: pendingReviewCount,
                            color: Colors.black54,
                            onTap: () =>
                                context.push("/profile/orders?tab=review"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SectionShell(
                      title: "Tiện ích của tôi",
                      child: ProfileUtilityGrid(items: utilities),
                    ),
                    if (vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _refreshAll() async {
    final profileVm = context.read<ProfileViewmodel>();
    final evaluateVm = context.read<EvaluateViewmodel>();
    final chatVm = context.read<ChatViewmodel>();

    await profileVm.refresh();

    if (!mounted) return;
    if (profileVm.completedOrders.isNotEmpty) {
      await evaluateVm.syncEvaluateStatusForOrders(
        profileVm.completedOrders.map((e) => e.id).toList(),
      );
    }

    await evaluateVm.refresh();
    await chatVm.loadConversations(silent: true);
  }

  // void _scheduleEvaluateStatusSync(
  //   List<OrderOut> completedOrders,
  //   EvaluateViewmodel evaluateVm,
  // ) {
  //   final orderIds = completedOrders.map((e) => e.id).toList(growable: false);
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (!mounted || orderIds.isEmpty) return;
  //     evaluateVm.syncEvaluateStatusForOrders(orderIds);
  //   });
  // }

  String _supportingText(ProfileViewmodel vm) {
    final phone = (vm.profile?.phone ?? "").trim();
    if (phone.isNotEmpty) return phone;
    return "Cập nhật hồ sơ để nhận hỗ trợ nhanh hơn";
  }

  Future<void> _openEditProfileDialog(AuthViewmodel auth) async {
    final vm = context.read<ProfileViewmodel>();
    final formValue = await showDialog<ProfileEditValue>(
      context: context,
      builder: (dialogContext) {
        return AnimatedBuilder(
          animation: vm,
          builder: (_, __) {
            return ProfileEditDialog(
              profile: vm.profile,
              fallbackName: _pickName(vm.profile?.name, auth.user?.username),
              isSubmitting: vm.isUpdatingProfile,
              isUploadingAvatar: vm.isUploadingAvatar,
              onPickAvatarFromGallery: () => _pickAvatar(ImageSource.gallery),
              onCaptureAvatar: () => _pickAvatar(ImageSource.camera),
            );
          },
        );
      },
    );

    if (formValue == null) return;

    try {
      final hasNewAvatar = (formValue.avatarFilePath ?? "").trim().isNotEmpty;
      if (hasNewAvatar) {
        await vm.uploadAvatar(
          filePath: formValue.avatarFilePath!,
          fileName: formValue.avatarFileName,
        );
      }

      await vm.updateProfile(
        name: formValue.name,
        phone: formValue.phone,
        gender: formValue.gender,
        birthday: formValue.birthday,
        avatar: hasNewAvatar
            ? (vm.profile?.avatar ?? formValue.avatar)
            : formValue.avatar,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thông tin thành công.")),
      );
    } catch (_) {
      if (!mounted) return;
      final message = vm.errorMessage ?? "Cập nhật thông tin thất bại.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<XFile?> _pickAvatar(ImageSource source) async {
    try {
      return await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        preferredCameraDevice: CameraDevice.front,
      );
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể chọn hoặc chụp ảnh.")),
      );
      return null;
    }
  }

  Future<void> _confirmLogout(AuthViewmodel auth) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Xác nhận đăng xuất"),
          content: const Text("Bạn có chắc muốn đăng xuất không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Đăng xuất"),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;
    await auth.logout();
  }

  String _pickName(String? profileName, String? username) {
    final name = (profileName ?? "").trim();
    if (name.isNotEmpty) return name;
    final fallback = (username ?? "Khách hàng").trim();
    return fallback.isEmpty ? "Khách hàng" : fallback;
  }

  String? _resolveAvatar(String? avatar) {
    if (avatar == null || avatar.trim().isEmpty) return null;
    final raw = avatar.trim();
    if (raw.startsWith("http://") || raw.startsWith("https://")) {
      return raw;
    }
    if (raw.startsWith("/")) {
      return "${AppConstants.baseUrl}$raw";
    }
    return "${AppConstants.baseUrl}/$raw";
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget child;

  const _SectionShell({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF253041),
                  ),
                ),
              ),
              if ((actionLabel ?? "").trim().isNotEmpty)
                TextButton(
                  onPressed: onActionTap,
                  style: TextButton.styleFrom(foregroundColor: Colors.black54),
                  child: Text(actionLabel!),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
