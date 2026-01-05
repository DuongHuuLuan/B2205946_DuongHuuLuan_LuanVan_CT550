import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_repository.dart';
import 'package:flutter/material.dart';

class ProductViewmodel extends ChangeNotifier {
  final ProductRepository _repository;
  ProductViewmodel(this._repository);

  bool isLoading = false;
  String? errorMessage;
  List<Product> products = [];
  Product? product;
  String? selectedVariantId;

  Future<void> getAllProduct({String? categoryId}) async {
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

  Future<void> productDetail(String id) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      product = await _repository.productDetail(id);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectVariant(String variantId) {
    selectedVariantId = variantId;
    notifyListeners();
  }
}
