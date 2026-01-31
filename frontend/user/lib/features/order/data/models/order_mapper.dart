import 'package:b2205946_duonghuuluan_luanvan/app/utils/json_extension.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';

class OrderMapper {
  static OrderOut fromJson(Map<String, dynamic> json) {
    final id = _toInt(json["id"]);
    final status = json["status"]?.toString() ?? "";
    final createdAt = _toDate(json["created_at"] ?? json["createdAt"]);

    final rawDetails = json["order_details"];
    double total = 0;

    if (rawDetails is List) {
      for (var item in rawDetails) {
        if (item is Map) {
          final price = _toDouble(item["price"]);
          final quantity = _toInt(item["quantity"]);
          total += price * quantity;
        }
      }
    }
    return OrderOut(id: id, status: status, createdAt: createdAt, total: total);
  }

  static int _toInt(dynamic value) => (value as Object?).toInt();
  static double _toDouble(dynamic value) => (value as Object?).toDouble();
  static DateTime? _toDate(dynamic value) => (value as Object?).toDateTime();
}
