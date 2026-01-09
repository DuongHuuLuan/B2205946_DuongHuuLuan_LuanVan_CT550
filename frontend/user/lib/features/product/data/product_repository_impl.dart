import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/data/model/product_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/data/product_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_repository.dart';
import 'package:dio/dio.dart';

class ProductRepositoryImpl extends ProductRepository {
  final ProductApi _api;
  ProductRepositoryImpl(this._api);

  @override
  Future<List<Product>> getAllProduct({int? categoryId}) async {
    try {
      final response = await _api.getAllProduct(categoryId: categoryId);
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      final list = (raw as List).cast<Map<String, dynamic>>();
      return list.map(ProductMapper.fromJson).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Product> productDetail(int id) async {
    try {
      final response = await _api.productDetail(id);
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      return ProductMapper.fromJson(raw as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

