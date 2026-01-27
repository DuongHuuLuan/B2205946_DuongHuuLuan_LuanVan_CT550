import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_image.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/warehouse/domain/warehouse_repository.dart';
import 'package:flutter/material.dart';

class ProductViewmodel extends ChangeNotifier {
  final ProductRepository _repository;
  final WarehouseRepository _warehouseRepository;
  ProductViewmodel(this._repository, this._warehouseRepository);

  // Trạng thái
  bool isLoading = false;
  String? errorMessage;

  // Ph?n trang (lazy load)
  static const int _defaultPerPage = 8;
  int _page = 1;
  int _perPage = _defaultPerPage;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int? _currentCategoryId;

  List<Product> products = []; // danh sách cho ProductPage
  Product? product; // Chi tiết cho trang ProductDetail

  int? _selectedColorId;
  int? _selectedSizeId;
  int _imgIndex = 0;
  int _quantity = 1;
  int? _availableQuantity;
  bool _stockLoading = false;

  // getter (sử dụng lại các extension)
  int? get selectedColorId => _selectedColorId;
  int? get selectedSizeId => _selectedSizeId;
  int get imgIndex => _imgIndex;
  int get quantity => _quantity;
  int? get availableQuantity => _availableQuantity;
  bool get isStockLoading => _stockLoading;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  int get perPage => _perPage;

  List<ProductDetail> get colors => product?.uniqueColors ?? [];
  List<ProductDetail> get sizes =>
      product?.getUniqueSizesByColor(_selectedColorId) ?? [];
  ProductDetail? get selectedProductDetail =>
      product?.findProductDetail(_selectedColorId, _selectedSizeId);
  List<ProductImage> get displayProductImages =>
      product?.filterProductImages(_selectedColorId) ?? [];

  // góm nhóm sản phẩm theo Category (cho ProductPage)
  Map<int, List<Product>> get productsByCategory {
    final map = <int, List<Product>>{};
    for (final p in products) {
      map.putIfAbsent(p.categoryId, () => []).add(p);
    }
    return map;
  }

  Future<void> getAllProduct({int? categoryId, int? page, int? perPage}) async {
    isLoading = true;
    errorMessage = null;
    _isLoadingMore = false;
    _currentCategoryId = categoryId;
    notifyListeners();
    try {
      products = await _repository.getAllProduct(
        categoryId: categoryId,
        page: page,
        perPage: perPage,
      );
      if (page != null || perPage != null) {
        _page = page ?? 1;
        _perPage = perPage ?? _perPage;
        _hasMore = products.length >= _perPage;
      } else {
        _page = 1;
        _hasMore = false;
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInitialPaged({int? categoryId, int? perPage}) async {
    isLoading = true;
    errorMessage = null;
    _currentCategoryId = categoryId;
    _page = 1;
    _perPage = perPage ?? _defaultPerPage;
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();

    try {
      final list = await _repository.getAllProduct(
        categoryId: categoryId,
        page: _page,
        perPage: _perPage,
      );
      products = list;
      if (list.length < _perPage) {
        _hasMore = false;
      }
    } catch (e) {
      errorMessage = e.toString();
      products = [];
      _hasMore = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _page + 1;
    try {
      final list = await _repository.getAllProduct(
        categoryId: _currentCategoryId,
        page: nextPage,
        perPage: _perPage,
      );
      if (list.isEmpty) {
        _hasMore = false;
      } else {
        products.addAll(list);
        _page = nextPage;
        if (list.length < _perPage) {
          _hasMore = false;
        }
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
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
      _loadSelectedStock();
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
    _loadSelectedStock();
    notifyListeners();
  }

  void selectSize(int sizeId) {
    _selectedSizeId = sizeId;
    _loadSelectedStock();
    notifyListeners();
  }

  void setImgIndex(int index) {
    _imgIndex = index;
    notifyListeners();
  }

  void updateQuantity(int delta) {
    final maxStock = _availableQuantity ?? 0;
    final newQuantity = _quantity + delta;
    if (newQuantity >= 1 && newQuantity <= maxStock) {
      _quantity = newQuantity;
      notifyListeners();
    }
  }

  Future<void> _loadSelectedStock() async {
    final detail = selectedProductDetail;
    if (detail == null || product == null) {
      _availableQuantity = null;
      _stockLoading = false;
      return;
    }

    _stockLoading = true;
    _availableQuantity = null;
    notifyListeners();
    try {
      final quantity = await _warehouseRepository.getTotalStock(
        productId: product!.id,
        colorId: detail.colorId,
        sizeId: detail.sizeId,
      );
      _availableQuantity = quantity;
    } catch (_) {
      _availableQuantity = null;
    } finally {
      _stockLoading = false;
      notifyListeners();
    }
  }
}
