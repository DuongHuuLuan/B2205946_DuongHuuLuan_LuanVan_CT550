import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/data/cart_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/data/models/cart_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart_repository.dart';
import 'package:dio/dio.dart';

class CartRepositoryImpl implements CartRepository {
  final CartApi _api;
  CartRepositoryImpl(this._api);

  @override
  Future<Cart> getCart() async {
    try {
      final response = await _api.getCart();
      final data = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      return CartMapper.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Cart> addToCart({
    required int productDetailId,
    int quantity = 1,
  }) async {
    try {
      final response = await _api.addCartDetail(
        productDetailId: productDetailId,
        quantity: quantity,
      );
      final data = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      return CartMapper.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Cart> updateCartDetail({
    required int cartDetailId,
    required int newQuantity,
  }) async {
    try {
      final response = await _api.updateCartDetail(
        cartDetailId: cartDetailId,
        newQuantity: newQuantity,
      );
      final data = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      return CartMapper.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<void> deleteCartDetail({required int cartDetailId}) async {
    try {
      await _api.deleteCartDetail(cartDetailId: cartDetailId);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
