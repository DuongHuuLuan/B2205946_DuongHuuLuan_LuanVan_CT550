import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_repository.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/domain/profile.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/domain/profile_repository.dart';

class ProfileViewmodel extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  final OrderRepository _orderRepository;

  ProfileViewmodel(this._profileRepository, this._orderRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Profile? profile;
  List<OrderOut> orders = [];

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
    } catch (e, stacktrace) {
      _errorMessage = e.toString();
      debugPrint("ProfileViewmodel error: $e");
      debugPrint("ProfileViewmodel stacktrace: $stacktrace");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get pendingCount => orders.where((o) => o.status == "pending").length;

  int get shippingCount => orders.where((o) => o.status == "shipping").length;

  int get completedCount => orders.where((o) => o.status == "completed").length;

  int get cancelledCount => orders.where((o) => o.status == "cancelled").length;
}
