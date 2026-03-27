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
  String _currentKeyword = '';

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
  String get currentKeyword => _currentKeyword;
  bool get hasActiveKeyword => _currentKeyword.isNotEmpty;

  List<ProductDetail> get activeProductDetails =>
      product?.productDetails.where((element) => element.isActive).toList() ??
      const [];
  bool get hasAnyActiveDetails => activeProductDetails.isNotEmpty;

  List<ProductDetail> get colors {
    final p = product;
    if (p == null) return const [];
    final unique = p.uniqueColors;
    return unique.where((color) {
      return activeProductDetails.any((d) => d.colorId == color.colorId);
    }).toList();
  }

  List<ProductDetail> get sizes {
    final p = product;
    if (p == null) return const [];

    return p
        .getUniqueSizesByColor(_selectedColorId)
        .where((e) => e.isActive)
        .toList();
  }

  ProductDetail? get selectedProductDetail {
    final p = product;
    if (p == null) return null;
    final detail = p.findProductDetail(_selectedColorId, _selectedSizeId);
    if (detail == null || !detail.isActive) return null;
    return detail;
  }

  List<ProductImage> get displayProductImages =>
      product?.galleryImagesForColor(_selectedColorId) ?? const [];

  bool get isSelectedDetailsInactive {
    final p = product;
    if (p == null) return false;

    final detail = p.findProductDetail(_selectedColorId, _selectedSizeId);
    if (detail == null) return false;
    return !detail.isActive;
  }

  // góm nhóm sản phẩm theo Category (cho ProductPage)
  Map<int, List<Product>> get productsByCategory {
    final map = <int, List<Product>>{};
    for (final p in products) {
      map.putIfAbsent(p.categoryId, () => []).add(p);
    }
    return map;
  }

  List<Product> _filterProductsForUser(List<Product> input) {
    return input.where((p) => p.productDetails.any((d) => d.isActive)).toList();
  }

  Future<void> getAllProduct({
    int? categoryId,
    int? page,
    int? perPage,
    String? keyword,
  }) async {
    isLoading = true;
    errorMessage = null;
    _isLoadingMore = false;
    _currentCategoryId = categoryId;
    _currentKeyword = keyword?.trim() ?? '';
    notifyListeners();
    try {
      final list = await _repository.getAllProduct(
        categoryId: categoryId,
        page: page,
        perPage: perPage,
        keyword: _currentKeyword.isEmpty ? null : _currentKeyword,
      );
      products = _filterProductsForUser(list);
      if (page != null || perPage != null) {
        _page = page ?? 1;
        _perPage = perPage ?? _perPage;
        _hasMore = list.length >= _perPage;
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

  Future<void> loadInitialPaged({
    int? categoryId,
    int? perPage,
    String? keyword,
  }) async {
    isLoading = true;
    errorMessage = null;
    _currentCategoryId = categoryId;
    _currentKeyword = keyword?.trim() ?? '';
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
        keyword: _currentKeyword.isEmpty ? null : _currentKeyword,
      );
      products = _filterProductsForUser(list);

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
        keyword: _currentKeyword.isEmpty ? null : _currentKeyword,
      );
      final filtered = _filterProductsForUser(list);

      if (list.isEmpty) {
        _hasMore = false;
      } else {
        products.addAll(filtered);
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
    final activeDetails = activeProductDetails;

    if (product != null && activeDetails.isNotEmpty) {
      final preferredColors = colors;

      _selectedColorId = preferredColors.isNotEmpty
          ? preferredColors.first.colorId
          : activeDetails.first.colorId;

      final preferredSizes = sizes;
      _selectedSizeId = preferredSizes.isNotEmpty
          ? preferredSizes.first.sizeId
          : activeDetails.first.sizeId;

      _imgIndex = 0;
      _quantity = 1;
      _loadSelectedStock();
      return;
    }

    _selectedColorId = null;
    _selectedSizeId = null;
    _imgIndex = 0;
    _quantity = 1;
    _availableQuantity = null;
    _stockLoading = false;
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
    final images = displayProductImages;
    if (images.isEmpty) {
      if (_imgIndex == 0) return;
      _imgIndex = 0;
      notifyListeners();
      return;
    }

    final safeIndex = index.clamp(0, images.length - 1);
    if (_imgIndex == safeIndex) return;
    _imgIndex = safeIndex;
    notifyListeners();
  }

  void updateQuantity(int delta) {
    final detail = selectedProductDetail;
    if (detail == null || !detail.isActive) return;
    if (_stockLoading || _availableQuantity == null) return;

    final maxStock = _availableQuantity!;
    final newQuantity = _quantity + delta;

    if (maxStock <= 0) {
      if (_quantity != 1) {
        _quantity = 1;
        notifyListeners();
      }
      return;
    }
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

    if (!detail.isActive) {
      _availableQuantity = 0;
      _stockLoading = false;
      _quantity = 1;
      notifyListeners();
      return;
    }

    _stockLoading = true;
    notifyListeners();

    try {
      final quantity = await _warehouseRepository.getTotalStock(
        productId: product!.id,
        colorId: detail.colorId,
        sizeId: detail.sizeId,
      );
      _availableQuantity = quantity;

      if (_quantity > quantity && quantity > 0) {
        _quantity = quantity;
      }
      if (quantity <= 0) {
        _quantity = 1;
      }
    } catch (_) {
    } finally {
      _stockLoading = false;
      notifyListeners();
    }
  }
}
