import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_repository.dart';
import 'package:flutter/material.dart';

class CartViewmodel extends ChangeNotifier {
  final CartRepository _repository;
  final ProductRepository _productRepository;
  final DiscountRepository _discountRepository;
  CartViewmodel(
    this._repository,
    this._productRepository,
    this._discountRepository,
  );

  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Cart? cart;
  Map<int, Product> _productByDetailid = {};

  List<Discount> discounts = [];
  bool _isDiscountLoading = false;
  String? _discountError;
  Set<int> _lastDiscountCategoryIds = {};

  bool get isDiscountLoading => _isDiscountLoading;
  String? get discountError => _discountError;

  List<CartDetail> get cartDetails => cart?.cartDetails ?? [];
  double get totalPrice => cart?.totalPrice ?? 0;
  Product? productForDetail(int detailId) => _productByDetailid[detailId];
  int? categoryIdForDetail(int detailId) =>
      _productByDetailid[detailId]?.categoryId;

  Future<void> _loadProductMap() async {
    if (_productByDetailid.isNotEmpty) return;
    try {
      final products = await _productRepository.getAllProduct();
      final map = <int, Product>{};
      for (final product in products) {
        for (final detail in product.productDetails) {
          map[detail.id] = product;
        }
      }
      _productByDetailid = map;
    } catch (e) {}
  }

  Future<void> fetchDiscountsForCategories(List<int> categoryIds) async {
    final normalized = categoryIds.toSet();
    if (normalized.isEmpty) {
      discounts = [];
      _lastDiscountCategoryIds = {};
      notifyListeners();
      return;
    }
    if (_lastDiscountCategoryIds.length == normalized.length &&
        _lastDiscountCategoryIds.containsAll(normalized)) {
      return;
    }
    _lastDiscountCategoryIds = normalized;
    _isDiscountLoading = true;
    _discountError = null;
    notifyListeners();
    try {
      discounts = await _discountRepository.getDiscountsForCart(
        categoryIds: normalized.toList(),
      );
    } catch (e) {
      _discountError = e.toString();
      discounts = [];
    } finally {
      _isDiscountLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      cart = await _repository.getCart();
      await _loadProductMap();
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
      await _loadProductMap();
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
      await _loadProductMap();
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
      await _loadProductMap();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
