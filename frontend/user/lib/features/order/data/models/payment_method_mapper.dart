import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/payment_method.dart';

class PaymentMethodMapper {
  static PaymentMethod fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json["id"] as int,
      name: json["name"] as String? ?? "",
    );
  }
}
