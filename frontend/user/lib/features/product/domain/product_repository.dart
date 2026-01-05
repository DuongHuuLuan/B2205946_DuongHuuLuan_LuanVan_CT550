import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAllProduct({String? categoryId});
  Future<Product> productDetail(String id);
}
