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

  int get cartBadgeCount =>
      cartDetails.fold(0, (total, item) => total + item.quantity);

  List<CartDetail> get cartDetails => cart?.cartDetails ?? [];
  double get totalPrice => cart?.totalPrice ?? 0;
  bool get canCheckoutCart => cart?.canCheckout ?? true;
  bool get hasInvalidItems =>
      cartDetails.any((element) => !element.canCheckout);

  Product? productForDetail(int detailId) => _productByDetailid[detailId];
  int? categoryIdForDetail(int detailId) =>
      _productByDetailid[detailId]?.categoryId;

  List<CartDetail> validSelectedItems(Iterable<int> selectedIds) {
    return cartDetails
        .where(
          (detail) => selectedIds.contains(detail.id) && detail.canCheckout,
        )
        .toList();
  }

  bool selectionHasInvalidItems(Iterable<int> selectedIds) {
    return cartDetails
        .where((detail) => selectedIds.contains(detail.id))
        .any((detail) => !detail.canCheckout);
  }

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

  void _resetDiscountCache({bool clearDiscounts = false}) {
    _lastDiscountCategoryIds = {};
    if (clearDiscounts) {
      discounts = [];
      _discountError = null;
      _isDiscountLoading = false;
    }
  }

  double _calculateCartTotal(List<CartDetail> details) {
    return details.fold(0, (sum, item) => sum + item.lineTotal);
  }

  Future<void> fetchDiscountsForCategories(List<int> categoryIds) async {
    final normalized = categoryIds.toSet();
    if (normalized.isEmpty) {
      discounts = [];
      _lastDiscountCategoryIds = {};
      _discountError = null;
      _isDiscountLoading = false;
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
      _resetDiscountCache(clearDiscounts: true);
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
      _resetDiscountCache(clearDiscounts: true);
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
    final previousCart = cart;
    final currentCart = cart;

    if (currentCart != null) {
      var hasChange = false;
      final updatedDetails = currentCart.cartDetails.map((detail) {
        if (detail.id != cartDetailId) return detail;
        hasChange = detail.quantity != newQuantity;
        return detail.copyWith(quantity: newQuantity);
      }).toList();

      if (!hasChange) {
        return;
      }

      cart = currentCart.copyWith(
        cartDetails: updatedDetails,
        totalPrice: _calculateCartTotal(updatedDetails),
      );
    }

    _isLoading = true;
    _errorMessage = null;
    _resetDiscountCache(clearDiscounts: true);
    notifyListeners();
    try {
      cart = await _repository.updateCartDetail(
        cartDetailId: cartDetailId,
        newQuantity: newQuantity,
      );
      await _loadProductMap();
      _resetDiscountCache(clearDiscounts: true);
    } catch (e) {
      cart = previousCart;
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
      _resetDiscountCache(clearDiscounts: true);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String statusLabel(CartDetail item) {
    switch (item.cartStatus) {
      case "inactive":
        return "Ngừng bán";
      case "out_of_stock":
        return "Hết hàng";
      case "insufficient_stock":
        return "Vượt tồn kho";
      default:
        return "Còn hàng";
    }
  }
}
