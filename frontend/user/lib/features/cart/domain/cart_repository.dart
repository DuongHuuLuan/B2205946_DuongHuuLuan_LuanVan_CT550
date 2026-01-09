import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';

abstract class CartRepository {
  Future<Cart> getCart();
  Future<Cart> addToCart({required int productDetailId, int quantity});
  Future<Cart> updateCartDetail({
    required int cartDetailId,
    required int newQuantity,
  });
  Future<void> deleteCartDetail({required int cartDetailId});
}
