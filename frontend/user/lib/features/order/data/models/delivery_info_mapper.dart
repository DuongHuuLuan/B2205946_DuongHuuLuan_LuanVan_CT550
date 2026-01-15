import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/delivery_info.dart';

class DeliveryInfoMapper {
  static DeliveryInfo fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      id: (json["id"] as num?)?.toInt() ?? 0,
      userId: (json["user_id"] as num?)?.toInt() ?? 0,
      name: json["name"]?.toString() ?? "",
      address: json["address"]?.toString() ?? "",
      phone: json["phone"]?.toString() ?? "",
      districtId: (json["district_id"] as num?)?.toInt(),
      wardCode: json["ward_code"]?.toString(),
    );
  }
}
