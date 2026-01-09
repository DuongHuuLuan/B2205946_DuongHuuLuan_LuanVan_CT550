import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/data/model/product_detail_mapper.dart';

class CartMapper extends Cart {
  CartMapper({
    required super.id,
    required super.userId,
    required super.cartDetails,
    required super.totalPrice,
  });

  factory CartMapper.fromJson(Map<String, dynamic> json) {
    final cartDetailsJson = (json["cart_details"] as List? ?? [])
        .cast<Map<String, dynamic>>();

    int toInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? "") ?? 0;

    return CartMapper(
      id: toInt(json["id"]),
      userId: toInt(json["user_id"]),
      cartDetails: cartDetailsJson
          .map<CartDetail>((e) => CartDetailMapper.fromJson(e))
          .toList(),
      totalPrice: double.tryParse(json["total_price"].toString()) ?? 0,
    );
  }
}

class CartDetailMapper extends CartDetail {
  CartDetailMapper({
    required super.id,
    required super.productDetailId,
    required super.quantity,
    required super.productDetail,
  });

  factory CartDetailMapper.fromJson(Map<String, dynamic> json) {
    final productDetailJson =
        (json["product_detail"] ?? {}) as Map<String, dynamic>;

    int toInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? "") ?? 0;

    return CartDetailMapper(
      id: toInt(json["id"]),
      productDetailId: toInt(json["product_detail_id"]),
      quantity: toInt(json["quantity"]),
      productDetail: ProductDetailMapper.fromJson(productDetailJson),
    );
  }
}
