import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:b2205946_duonghuuluan_luanvan/app/utils/currency_ext.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/viewmodel/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProfileViewmodel>().load());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewmodel>();
    final vm = context.watch<ProfileViewmodel>();
    final user = auth.user;
    final profile = vm.profile;

    final displayName = _pickName(profile?.name, user?.username);
    final displayEmail = (user?.email ?? "Chưa có email").trim();
    final avatarUrl = _resolveAvatar(profile?.avatar);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final quickItems = [
      _QuickItem(
        icon: Icons.verified_outlined,
        label: "Chờ xác nhận",
        count: vm.pendingCount,
        tone: colorScheme.onPrimary,
      ),
      _QuickItem(
        icon: Icons.local_shipping_outlined,
        label: "Chờ giao hàng",
        count: vm.shippingCount,
        tone: Colors.orange.shade700,
      ),
      _QuickItem(
        icon: Icons.rate_review_outlined,
        label: "Đánh giá",
        count: 0,
        tone: Colors.green.shade700,
      ),
      _QuickItem(
        icon: Icons.discount_outlined,
        label: "Kho mã giảm giá",
        count: 0,
        tone: colorScheme.secondary,
      ),
    ];

    final vouchers = <_VoucherItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hồ sơ"),
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
            onPressed: vm.isLoading ? null : () => vm.refresh(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: "Đăng xuất",
            onPressed: auth.isAuthenticated ? () => auth.logout() : null,
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
                  _ProfileHeader(
                    name: displayName,
                    email: displayEmail,
                    avatarUrl: avatarUrl,
                  ),
                  const SizedBox(height: 14),
                  const _SectionHeader(title: "Đơn hàng của tôi"),
                  _QuickGrid(items: quickItems),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: "Lịch sử đơn hàng",
                    actionLabel: "Xem tất cả",
                    onAction: () {},
                  ),
                  _HistoryList(items: vm.orders),
                  if (vm.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        vm.errorMessage!,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: "Kho mã giảm giá",
                    actionLabel: "Xem thêm",
                    onAction: () {},
                  ),
                  _VoucherList(items: vouchers),
                  const SizedBox(height: 12),
                  Text(
                    "Bạn có thể quản lý thông tin cá nhân, theo dõi đơn hàng và ưu đãi tại đây.",
                    style: textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
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

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : "?";
    final gradient = LinearGradient(
      colors: [
        scheme.primary,
        Color.lerp(scheme.primary, scheme.secondary, 0.28) ?? scheme.primary,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: gradient,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              child: const Text("Chỉnh sửa"),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: titleStyle),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  final List<_QuickItem> items;
  const _QuickGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.tone.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.tone),
                  ),
                  const Spacer(),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item.count} mục",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: item.tone),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<OrderOut> items;
  const _HistoryList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          "Chưa có đơn hàng nào.",
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  title: Text(
                    "#DH-${item.id}",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text("Ngày đặt: ${_formatDate(item.createdAt)}"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusChip(status: item.status),
                      const SizedBox(height: 6),
                      Text(
                        item.total > 0 ? item.total.toVnd() : "--",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "--/--/----";
    final d = date.day.toString().padLeft(2, "0");
    final m = date.month.toString().padLeft(2, "0");
    return "$d/$m/${date.year}";
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = _labelFor(status);
    final tone = _toneFor(status, scheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: tone),
      ),
    );
  }

  String _labelFor(String value) {
    switch (value) {
      case "pending":
        return "Chờ xác nhận";
      case "shipping":
        return "Đang giao";
      case "completed":
        return "Đã hoàn tất";
      case "cancelled":
        return "Đã hủy";
      default:
        return value;
    }
  }

  Color _toneFor(String value, ColorScheme scheme) {
    switch (value) {
      case "pending":
        return Colors.orange.shade700;
      case "shipping":
        return scheme.primary;
      case "completed":
        return Colors.green.shade700;
      case "cancelled":
        return Colors.red.shade700;
      default:
        return scheme.primary;
    }
  }
}

class _VoucherList extends StatelessWidget {
  final List<_VoucherItem> items;
  const _VoucherList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          "Chưa có mã giảm giá nào.",
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.confirmation_number_outlined,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.code,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.expiry,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final int count;
  final Color tone;

  _QuickItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.tone,
  });
}

class _VoucherItem {
  final String code;
  final String description;
  final String expiry;

  const _VoucherItem({
    required this.code,
    required this.description,
    required this.expiry,
  });
}
