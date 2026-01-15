import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/vnpay.dart';

class VnpayMapper {
  static VnpayPaymentUrl fromJson(Map<String, dynamic> json) {
    return VnpayPaymentUrl(paymentUrl: json["payment_url"] as String? ?? "");
  }
}
