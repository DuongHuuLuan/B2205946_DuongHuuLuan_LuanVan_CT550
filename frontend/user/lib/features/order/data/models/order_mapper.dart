import 'package:b2205946_duonghuuluan_luanvan/app/utils/json_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/delivery_info_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/payment_method_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';

class OrderMapper {
  static OrderOut fromJson(Map<String, dynamic> json) {
    final id = _toInt(json["id"]);
    final status = json["status"]?.toString() ?? "";
    final createdAt = _toDate(json["created_at"] ?? json["createdAt"]);
    final discountCode = _pickDiscountCode(json);
    final deliveryInfo = _parseDeliveryInfo(json["delivery_info"]);
    final paymentMethod = _parsePaymentMethod(json["payment_method"]);

    final orderDetails = _parseOrderDetails(json["order_details"]);
    final subtotal = orderDetails.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    final shippingFee = _toDouble(json["shipping_fee"]);
    final total = subtotal + shippingFee;

    return OrderOut(
      id: id,
      status: status,
      createdAt: createdAt,
      subtotal: subtotal,
      shippingFee: shippingFee,
      total: total,
      orderDetails: orderDetails,
      discountCode: discountCode,
      deliveryInfo: deliveryInfo,
      paymentMethod: paymentMethod,
    );
  }

  static dynamic _castMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return null;
  }

  static dynamic _parseDeliveryInfo(dynamic raw) {
    final json = _castMap(raw);
    if (json == null) return null;
    return DeliveryInfoMapper.fromJson(json);
  }

  static dynamic _parsePaymentMethod(dynamic raw) {
    final json = _castMap(raw);
    if (json == null) return null;
    return PaymentMethodMapper.fromJson(json);
  }

  static List<OrderDetailOut> _parseOrderDetails(dynamic rawDetails) {
    if (rawDetails is! List) return const [];
    final result = <OrderDetailOut>[];
    for (final item in rawDetails) {
      if (item is! Map) continue;
      result.add(
        OrderDetailOut(
          productDetailId: _toInt(item["product_detail_id"]),
          quantity: _toInt(item["quantity"]),
          price: _toDouble(item["price"]),
          productName: _toStringValue(item["product_name"]),
          colorName: _toNullableString(item["color_name"]),
          sizeName: _toNullableString(item["size_name"]),
          imageUrl: _toNullableString(item["image_url"]),
        ),
      );
    }
    return result;
  }

  static String? _pickDiscountCode(Map<String, dynamic> json) {
    final direct =
        _toNullableString(json["discount_code"]) ??
        _toNullableString(json["discountCode"]);
    if (direct != null) return direct;

    final applied = json["applied_discounts"];
    if (applied is List) {
      final names = <String>[];
      for (final item in applied) {
        if (item is Map) {
          final name = _toNullableString(item["name"]);
          if (name != null) names.add(name);
        }
      }
      if (names.isNotEmpty) {
        return names.join(", ");
      }
    }
    return null;
  }

  static String _toStringValue(dynamic value) {
    final text = value?.toString().trim() ?? "";
    return text.isEmpty ? "Sản phẩm" : text;
  }

  static String? _toNullableString(dynamic value) {
    final text = value?.toString().trim() ?? "";
    if (text.isEmpty) return null;
    return text;
  }

  static int _toInt(dynamic value) => (value as Object?).toInt();
  static double _toDouble(dynamic value) => (value as Object?).toDouble();
  static DateTime? _toDate(dynamic value) => (value as Object?).toDateTime();
}
