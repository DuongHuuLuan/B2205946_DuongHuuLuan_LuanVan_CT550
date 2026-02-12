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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Profile? profile;
  List<OrderOut> orders = [];
  List<Discount> availableDiscounts = [];
  final Set<int> _confirmingOrderIds = {};
  Set<int> get confirmingOrderIds => Set.unmodifiable(_confirmingOrderIds);

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
    } catch (e, stacktrace) {
      _errorMessage = e.toString();
      debugPrint("ProfileViewmodel error: $e");
      debugPrint("ProfileViewmodel stacktrace: $stacktrace");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    } catch (e, stacktrace) {
      _errorMessage = e.toString();
      debugPrint("ProfileViewmodel confirmOrderReceived error: $e");
      debugPrint(
        "ProfileViewmodel confirmOrderReceived stacktrace: $stacktrace",
      );
      rethrow;
    } finally {
      _confirmingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  final _cancellingOrderIds = <int>{};
  Set<int> get cancellingOrderIds => Set.unmodifiable(_cancellingOrderIds);
  Future<void> cancelOrder(int orderId) async {
    if (_cancellingOrderIds.contains(orderId)) return;
    _cancellingOrderIds.add(orderId);
    _errorMessage = null;
    notifyListeners();
    try {
      await _orderRepository.cancelOrder(orderId);
      orders = await _orderRepository.getOrderHistory();
    } catch (e, stacktrace) {
      _errorMessage = e.toString();
      debugPrint("ProfileViewmodel cancelOrder error: $e");
      debugPrint("ProfileViewmodel cancelOrder stacktrace: $stacktrace");
      rethrow;
    } finally {
      _cancellingOrderIds.remove(orderId);
      notifyListeners();
    }
  }

  String _normalizeStatus(String value) => value.trim().toLowerCase();

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
}
