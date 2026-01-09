import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';
import 'package:flutter/material.dart';

class ProductViewmodel extends ChangeNotifier {
  final ProductRepository _repository;
  ProductViewmodel(this._repository);

  // Trạng thái
  bool isLoading = false;
  String? errorMessage;

  List<Product> products = []; // danh sách cho ProductPage
  Product? product; // Chi tiết cho trang ProductDetail

  int? _selectedColorId;
  int? _selectedSizeId;
  int _imgIndex = 0;
  int _quantity = 1;

  // getter (sử dụng lại các extension)
  int? get selectedColorId => _selectedColorId;
  int? get selectedSizeId => _selectedSizeId;
  int get imgIndex => _imgIndex;
  int get quantity => _quantity;

  List<ProductDetail> get colors => product?.uniqueColors ?? [];
  List<ProductDetail> get sizes =>
      product?.getUniqueSizesByColor(_selectedColorId) ?? [];
  ProductDetail? get selectedVariant =>
      product?.findVariant(_selectedColorId, _selectedSizeId);
  List<ProductImage> get displayImages =>
      product?.filterImages(_selectedColorId) ?? [];

  // góm nhóm sản phẩm theo Category (cho ProductPage)
  Map<int, List<Product>> get productsByCategory {
    final map = <int, List<Product>>{};
    for (final p in products) {
      map.putIfAbsent(p.categoryId, () => []).add(p);
    }
    return map;
  }

  Future<void> getAllProduct({int? categoryId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      products = await _repository.getAllProduct(categoryId: categoryId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> productDetail(int id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      product = await _repository.productDetail(id);
      _resetSelection();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _resetSelection() {
    if (product != null && product!.productDetails.isNotEmpty) {
      _selectedColorId = product!.productDetails.first.colorId;
      _selectedSizeId = product!.productDetails.first.sizeId;
      _imgIndex = 0;
      _quantity = 1;
    }
  }

  void selectColor(int colorId) {
    _selectedColorId = colorId;
    _imgIndex = 0;

    final availableSizes = sizes;
    if (!availableSizes.any((element) => element.sizeId == _selectedSizeId)) {
      _selectedSizeId = availableSizes.isNotEmpty
          ? availableSizes.first.sizeId
          : null;
    }
    notifyListeners();
  }

  void selectSize(int sizeId) {
    _selectedSizeId = sizeId;
    notifyListeners();
  }

  void setImgIndex(int index) {
    _imgIndex = index;
    notifyListeners();
  }

  void updateQuantity(int delta) {
    final maxStock = selectedVariant?.stockQuantity ?? 1;
    final newQuantity = _quantity + delta;
    if (newQuantity >= 1 && newQuantity <= maxStock) {
      _quantity = newQuantity;
      notifyListeners();
    }
  }
}
