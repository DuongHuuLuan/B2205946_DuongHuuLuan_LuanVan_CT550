import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/ghn_models.dart';

class GhnMapper {
  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static List<GhnProvince> provinces(List<dynamic> json) {
    return json
        .map(
          (item) => GhnProvince(
            provinceId: _toInt(item["ProvinceID"]),
            provinceName: item["ProvinceName"]?.toString() ?? "",
          ),
        )
        .toList();
  }

  static List<GhnDistrict> districts(List<dynamic> json) {
    return json
        .map(
          (item) => GhnDistrict(
            districtId: _toInt(item["DistrictID"]),
            districtName: item["DistrictName"]?.toString() ?? "",
          ),
        )
        .toList();
  }

  static List<GhnWard> wards(List<dynamic> json) {
    return json
        .map(
          (item) => GhnWard(
            wardCode: item["WardCode"]?.toString() ?? "",
            wardName: item["WardName"]?.toString() ?? "",
          ),
        )
        .toList();
  }

  static List<GhnServiceOption> services(List<dynamic> json) {
    return json
        .map(
          (item) => GhnServiceOption(
            serviceId: _toInt(item["service_id"]),
            serviceTypeId: _toInt(item["service_type_id"]),
            shortName: item["short_name"]?.toString() ?? "",
          ),
        )
        .toList();
  }

  static GhnFee fee(Map<String, dynamic> json) {
    return GhnFee(
      total: _toDouble(json["total"]),
      serviceFee: _toDouble(json["service_fee"]),
      insuranceFee: _toDouble(json["insurance_fee"]),
    );
  }

  static GhnShipment shipment(Map<String, dynamic> json) {
    return GhnShipment(
      id: _toInt(json["id"]),
      orderId: _toInt(json["order_id"]),
      ghnOrderCode: json["ghn_order_code"]?.toString(),
      status: json["status"]?.toString(),
      shippingFee: _toDouble(json["shipping_fee"]),
    );
  }
}
