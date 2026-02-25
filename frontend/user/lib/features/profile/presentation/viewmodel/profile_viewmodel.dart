import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/domain/profile.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/domain/profile_repository.dart';
import 'package:flutter/material.dart';

class ProfileViewmodel extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  final OrderRepository _orderRepository;
  final CategoryRepository _categoryRepository;
  final DiscountRepository _discountRepository;

  ProfileViewmodel(
    this._profileRepository,
    this._orderRepository,
    this._categoryRepository,
    this._discountRepository,
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;
  bool _isUploadingAvatar = false;
  bool get isUploadingAvatar => _isUploadingAvatar;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Profile? profile;
  List<OrderOut> orders = [];
  List<Discount> availableDiscounts = [];
  final Set<int> _confirmingOrderIds = {};
  Set<int> get confirmingOrderIds => Set.unmodifiable(_confirmingOrderIds);

  final _cancellingOrderIds = <int>{};
  Set<int> get cancellingOrderIds => Set.unmodifiable(_cancellingOrderIds);

  Future<void> load() async {
    if (_isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      profile = await _profileRepository.getProfile();
      orders = await _orderRepository.getOrderHistory();
      await _loadAvailableDiscounts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmOrderReceived(int orderId) async {
    if (_confirmingOrderIds.contains(orderId)) return;

    _confirmingOrderIds.add(orderId);
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedOrder = await _orderRepository.confirmDelivery(orderId);
      final index = orders.indexWhere((order) => order.id == orderId);
      if (index >= 0) {
        orders[index] = updatedOrder;
      } else {
        orders = await _orderRepository.getOrderHistory();
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _confirmingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  Future<void> cancelOrder(int orderId) async {
    if (_cancellingOrderIds.contains(orderId)) return;
    _cancellingOrderIds.add(orderId);
    _errorMessage = null;
    notifyListeners();
    try {
      await _orderRepository.cancelOrder(orderId);
      orders = await _orderRepository.getOrderHistory();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _cancellingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  String _normalizeStatus(String value) => value.trim().toLowerCase();

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String gender,
    required DateTime? birthday,
    required String avatar,
  }) async {
    if (_isUpdatingProfile) return;

    _isUpdatingProfile = true;
    _errorMessage = null;
    notifyListeners();

    final payload = <String, dynamic>{
      "name": _normalizeOptionalText(name),
      "phone": _normalizeOptionalText(phone),
      "gender": _normalizeGender(gender),
      "birthday": birthday == null ? null : _formatBirthdayForApi(birthday),
      "avatar": _normalizeOptionalText(avatar),
    };

    try {
      profile = await _profileRepository.updateProfile(payload);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  Future<void> uploadAvatar({
    required String filePath,
    String? fileName,
  }) async {
    if (_isUploadingAvatar) return;

    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      profile = await _profileRepository.uploadAvatar(
        filePath: filePath,
        fileName: fileName,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  Future<void> _loadAvailableDiscounts() async {
    final categories = await _categoryRepository.getAll();
    final categoryIds = categories.map((c) => c.id).toSet().toList();
    if (categoryIds.isEmpty) {
      availableDiscounts = [];
      return;
    }

    final discounts = await _discountRepository.getDiscountsForCart(
      categoryIds: categoryIds,
    );

    final uniqueById = <int, Discount>{};
    for (final discount in discounts) {
      uniqueById[discount.id] = discount;
    }

    availableDiscounts = uniqueById.values.toList()
      ..sort((a, b) => a.endAt.compareTo(b.endAt));
  }

  List<OrderOut> ordersByStatus(String status) {
    final normalized = _normalizeStatus(status);
    return orders
        .where((o) => _normalizeStatus(o.status) == normalized)
        .toList();
  }

  List<OrderOut> get completedOrders => ordersByStatus("completed");

  int get pendingCount => ordersByStatus("pending").length;

  int get shippingCount => ordersByStatus("shipping").length;

  int get completedCount => completedOrders.length;

  int get cancelledCount => ordersByStatus("cancelled").length;

  String? _normalizeOptionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String? _normalizeGender(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized == "male" ||
        normalized == "female" ||
        normalized == "other") {
      return normalized;
    }
    return null;
  }

  String _formatBirthdayForApi(DateTime birthday) {
    final date = birthday.toLocal();
    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");
    return "${date.year}-$month-$day";
  }
}
