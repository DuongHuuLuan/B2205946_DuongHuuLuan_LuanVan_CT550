import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';

class OrderMapper {
  static OrderOut fromJson(Map<String, dynamic> json) {
    return OrderOut(
      id: int.tryParse(json["id"].toString()) ?? 0,
      status: json["status"]?.toString() ?? "",
    );
  }
}
