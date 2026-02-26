import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/domain/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/presentation/view/evaluate_create_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/presentation/viewmodel/evaluate_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/evaluate/presentation/widget/evaluate_history_section.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/viewmodel/profile_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/profile_edit_dialog.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/order_history_list.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/profile_header.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/quick_order_grid.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/widget/voucher_section.dart';
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
  String _selectedStatus = "pending";
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<ProfileViewmodel>().load();
    context.read<EvaluateViewmodel>().load(perPage: 10);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewmodel>();
    final vm = context.watch<ProfileViewmodel>();
    final evaluateVm = context.watch<EvaluateViewmodel>();
    final profile = vm.profile;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filteredOrders = vm.ordersByStatus(_selectedStatus);
    final completedOrders = vm.completedOrders;
    _scheduleEvaluateStatusSync(completedOrders, evaluateVm);
    final vouchers = vm.availableDiscounts
        .map(
          (discount) => VoucherItemData(
            code: discount.name,
            description: discount.description.trim().isNotEmpty
                ? discount.description.trim()
                : "Giảm ${_formatPercent(discount.percent)}% cho đơn hàng phù hợp",
            expiry: "HSD: ${_formatDate(discount.endAt)}",
            longDescription:
                "Sử dụng mã này để được giảm ngay ${_formatPercent(discount.percent)}% tổng giá trị đơn hàng. Áp dụng đến hết ngày ${_formatDate(discount.endAt)}.",
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Hồ sơ cá nhân", style: TextStyle(fontSize: 20)),
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
            tooltip: "Tải lại",
            onPressed: vm.isLoading
                ? null
                : () async {
                    await vm.refresh();
                    if (!mounted) return;
                    await context.read<EvaluateViewmodel>().refresh();
                  },
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(
                    name: _pickName(vm.profile?.name, auth.user?.username),
                    email: auth.user?.email ?? "Chưa có email",
                    avatarUrl: _resolveAvatar(vm.profile?.avatar),
                    onEditPressed: vm.isUpdatingProfile
                        ? null
                        : () => _openEditProfileDialog(auth),
                  ),
                  const SizedBox(height: 14),
                  const _SectionHeader(title: "Đơn hàng của tôi"),
                  QuickOrderGrid(
                    items: [
                      QuickOrderItem(
                        icon: Icons.pending_actions,
                        label: "Chờ xác nhận",
                        count: vm.pendingCount,
                        color: Colors.orange,
                        isSelected: _selectedStatus == "pending",
                        onTap: () => _setStatus("pending"),
                      ),
                      QuickOrderItem(
                        icon: Icons.local_shipping,
                        label: "Đang giao",
                        count: vm.shippingCount,
                        color: Colors.blue,
                        isSelected: _selectedStatus == "shipping",
                        onTap: () => _setStatus("shipping"),
                      ),
                      QuickOrderItem(
                        icon: Icons.check_circle_outlined,
                        label: "Đã giao",
                        count: vm.completedCount,
                        color: Colors.green,
                        isSelected: _selectedStatus == "completed",
                        onTap: () => _setStatus("completed"),
                      ),
                      QuickOrderItem(
                        icon: Icons.cancel,
                        label: "Đã hủy",
                        count: vm.cancelledCount,
                        color: Colors.red,
                        isSelected: _selectedStatus == "cancelled",
                        onTap: () => _setStatus("cancelled"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: "Đơn hàng: ${_statusLabel(_selectedStatus)}",
                  ),
                  OrderHistoryList(
                    orders: filteredOrders,
                    onConfirmReceived: _confirmOrderReceived,
                    confirmingOrderIds: vm.confirmingOrderIds,
                    onCancelOrder: _cancelOrder,
                    cancellingOrderIds: vm.cancellingOrderIds,
                    evaluatedOrderIds: evaluateVm.reviewedOrderIds,
                    evaluatingOrderIds: evaluateVm.creatingOrderIds,
                    onCreateEvaluate: _openCreateEvaluate,
                    onViewEvaluate: _openEvaluateDetail,
                    emptyMessage:
                        "Không có đơn hàng nào ở trạng thái ${_statusLabel(_selectedStatus).toLowerCase()}.",
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeader(title: "Lịch sử đơn hàng"),
                  OrderHistoryList(
                    orders: completedOrders,
                    onConfirmReceived: _confirmOrderReceived,
                    confirmingOrderIds: vm.confirmingOrderIds,
                    onCancelOrder: _cancelOrder,
                    cancellingOrderIds: vm.cancellingOrderIds,
                    evaluatedOrderIds: evaluateVm.reviewedOrderIds,
                    evaluatingOrderIds: evaluateVm.creatingOrderIds,
                    onCreateEvaluate: _openCreateEvaluate,
                    onViewEvaluate: _openEvaluateDetail,
                    emptyMessage: "Bạn chưa có đơn hàng giao thành công.",
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeader(title: "Lịch sử đánh giá"),
                  EvaluateHistorySection(),
                  if (vm.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        vm.errorMessage!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 18),
                  const _SectionHeader(title: "Kho mã giảm giá"),
                  VoucherSection(items: vouchers),
                  const SizedBox(height: 12),
                  Text(
                    "Hiển thị các mã giảm giá đang còn hiệu lực để bạn áp dụng khi mua hàng.",
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmOrderReceived(OrderOut order) async {
    final vm = context.read<ProfileViewmodel>();
    try {
      await vm.confirmOrderReceived(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xác nhận nhận hàng thành công.")),
      );
    } catch (_) {
      if (!mounted) return;
      final message = vm.errorMessage ?? "Xác nhận nhận hàng thất bại.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _cancelOrder(OrderOut order) async {
    final vm = context.read<ProfileViewmodel>();
    try {
      await vm.cancelOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Hủy đơn hàng thành công.")));
    } catch (_) {
      if (!mounted) return;
      final message = vm.errorMessage ?? "Hủy đơn hàng thất bại.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _scheduleEvaluateStatusSync(
    List<OrderOut> completedOrders,
    EvaluateViewmodel evaluateVm,
  ) {
    final orderIds = completedOrders.map((e) => e.id).toList(growable: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      evaluateVm.syncEvaluateStatusForOrders(orderIds);
    });
  }

  Future<void> _openCreateEvaluate(OrderOut order) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EvaluateCreatePage(orderId: order.id)),
    );

    if (result == true && mounted) {
      await context.read<EvaluateViewmodel>().refresh();
    }
  }

  Future<void> _openEvaluateDetail(OrderOut order) async {
    final evaluateVm = context.read<EvaluateViewmodel>();
    await evaluateVm.syncEvaluateStatusForOrders([order.id]);
    final evaluateId = evaluateVm.evaluateIdForOrder(order.id);
    if (evaluateId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chưa tìm thấy đánh giá cho đơn hàng này."),
        ),
      );
      return;
    }

    try {
      final evaluate = await evaluateVm.getEvaluateDetail(evaluateId);
      if (!mounted) return;
      await _showEvaluateDetailDialog(evaluate);
    } catch (_) {
      if (!mounted) return;
      final msg = evaluateVm.errorMessage ?? "Không thể tải chi tiết đánh giá.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _showEvaluateDetailDialog(EvaluateItem evaluate) async {
    final content = (evaluate.content ?? "").trim();
    final reply = (evaluate.adminReply ?? "").trim();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Đánh giá #EV-${evaluate.id}"),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Đơn hàng #DH-${evaluate.orderId}"),
                  const SizedBox(height: 8),
                  Text("Số sao: ${evaluate.rate}/5"),
                  const SizedBox(height: 8),
                  Text(content.isEmpty ? "(Không có nội dung)" : content),
                  if (evaluate.images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: evaluate.images
                          .map(
                            (img) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _resolveAvatar(img.imageUrl) ?? "",
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (reply.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Phản hồi từ người bán",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(reply),
                        ],
                      ),
                    )
                  else
                    Text(
                      "Chưa có phản hồi từ người bán.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Đóng",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
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
      const message = "Không thể chọn/chụp ảnh .";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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

  void _setStatus(String status) {
    if (_selectedStatus == status) return;
    setState(() => _selectedStatus = status);
  }

  String _statusLabel(String status) {
    switch (status) {
      case "pending":
        return "Chờ xác nhận";
      case "shipping":
        return "Đang giao";
      case "completed":
        return "Đã giao";
      case "cancelled":
        return "Đã hủy";
      default:
        return status;
    }
  }

  String _pickName(String? profileName, String? username) {
    final name = (profileName ?? "").trim();
    if (name.isNotEmpty) return name;
    final fallback = (username ?? "Khách hàng").trim();
    return fallback.isEmpty ? "Khách hàng" : fallback;
  }

  String _formatPercent(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, "0");
    final month = date.month.toString().padLeft(2, "0");
    final year = date.year.toString();
    return "$day/$month/$year";
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title, style: titleStyle)],
      ),
    );
  }
}
