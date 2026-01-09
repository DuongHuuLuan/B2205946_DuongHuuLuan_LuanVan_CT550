import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart_repository.dart';
import 'package:flutter/material.dart';

class CartViewmodel extends ChangeNotifier {
  final CartRepository _repository;
  CartViewmodel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Cart? cart;

  List<CartDetail> get cartDetails => cart?.cartDetails ?? [];
  double get totalPrice => cart?.totalPrice ?? 0;

  Future<void> fetchCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      cart = await _repository.getCart();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart({
    required int productDetailId,
    int quantity = 1,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      cart = await _repository.addToCart(
        productDetailId: productDetailId,
        quantity: quantity,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCartDetail({
    required int cartDetailId,
    required int newQuantity,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      cart = await _repository.updateCartDetail(
        cartDetailId: cartDetailId,
        newQuantity: newQuantity,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCartDetail({required int cartDetailId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteCartDetail(cartDetailId: cartDetailId);
      cart = await _repository.getCart();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
