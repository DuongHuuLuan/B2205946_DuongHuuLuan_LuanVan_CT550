import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/data/model/product_detail_mapper.dart';

class CartMapper extends Cart {
  CartMapper({
    required super.id,
    required super.userId,
    required super.cartDetails,
    required super.totalPrice,
    required super.canCheckout,
  });

  factory CartMapper.fromJson(Map<String, dynamic> json) {
    final cartDetailsJson = (json["cart_details"] as List? ?? [])
        .cast<Map<String, dynamic>>();

    int toInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? "") ?? 0;

    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final v = value.trim().toLowerCase();
        return v == "1" || v == "true";
      }
      return false;
    }

    return CartMapper(
      id: toInt(json["id"]),
      userId: toInt(json["user_id"]),
      cartDetails: cartDetailsJson
          .map<CartDetail>((e) => CartDetailMapper.fromJson(e))
          .toList(),
      totalPrice: double.tryParse(json["total_price"].toString()) ?? 0,
      canCheckout: toBool(json["can_checkout"]),
    );
  }
}

class CartDetailMapper extends CartDetail {
  CartDetailMapper({
    required super.id,
    required super.productDetailId,
    super.designId,
    super.designName,
    super.designPreviewImageUrl,
    required super.quantity,
    required super.productDetail,
    required super.isActive,
    required super.availableStock,
    required super.cartStatus,
    required super.statusMessage,
    required super.canCheckout,
  });

  factory CartDetailMapper.fromJson(Map<String, dynamic> json) {
    final productDetailJson =
        (json["product_detail"] ?? {}) as Map<String, dynamic>;

    int toInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? "") ?? 0;

    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final v = value.trim().toLowerCase();
        return v == "1" || v == "true";
      }
      return false;
    }

    return CartDetailMapper(
      id: toInt(json["id"]),
      productDetailId: toInt(json["product_detail_id"]),
      designId: toInt(json["design_id"]) <= 0 ? null : toInt(json["design_id"]),
      designName: json["design_name"]?.toString(),
      designPreviewImageUrl: json["design_preview_image_url"]?.toString(),
      quantity: toInt(json["quantity"]),
      productDetail: ProductDetailMapper.fromJson(productDetailJson),
      isActive: toBool(json["is_active"]),
      availableStock: toInt(json["available_stock"]),
      cartStatus: json["cart_status"]?.toString() ?? "ok",
      statusMessage: json["status_message"]?.toString(),
      canCheckout: toBool(json["can_checkout"]),
    );
  }
}
