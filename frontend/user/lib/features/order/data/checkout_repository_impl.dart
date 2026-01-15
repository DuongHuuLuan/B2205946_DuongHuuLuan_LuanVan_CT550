import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/checkout_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/delivery_info_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/ghn_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/order_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/payment_method_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/vnpay_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/checkout_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/payment_method.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/vnpay.dart';
import 'package:dio/dio.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutApi _api;
  CheckoutRepositoryImpl(this._api);

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return raw.cast<String, dynamic>();
    }
    if (raw is List && raw.isNotEmpty) {
      final first = raw.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      if (first is Map) {
        return first.cast<String, dynamic>();
      }
    }
    return const {};
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _api.getPaymentMethods();
      final data = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      final list = (data as List).cast<Map<String, dynamic>>();
      return list.map(PaymentMethodMapper.fromJson).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<DeliveryInfo>> getDeliveryInfos() async {
    try {
      final response = await _api.getDeliveryInfos();
      print("========= DEBUG: getDeliveryInfos =========");
      print("Kiểu dữ liệu nhận được: ${response.data.runtimeType}");
      print("Nội dung dữ liệu: ${response.data}");
      final data = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      final list = (data as List).cast<Map<String, dynamic>>();
      return list.map(DeliveryInfoMapper.fromJson).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<DeliveryInfo> createDeliveryInfo({
    required String name,
    required String phone,
    required String address,
    required int? districtId,
    required String? wardCode,
    bool isDefault = false,
  }) async {
    try {
      final response = await _api.createDeliveryInfo({
        "name": name,
        "phone": phone,
        "address": address,
        "district_id": districtId,
        "ward_code": wardCode,
        "default": isDefault,
      });
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      final data = _extractMap(raw);
      return DeliveryInfoMapper.fromJson(data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<OrderOut> createOrder(OrderCreate order) async {
    try {
      final response = await _api.createOrder({
        "delivery_info_id": order.deliveryInfoId,
        "payment_method_id": order.paymentMethodId,
        "order_items": order.items
            .map(
              (item) => {
                "product_detail_id": item.productDetailId,
                "quantity": item.quantity,
              },
            )
            .toList(),
      });
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      final data = _extractMap(raw);
      return OrderMapper.fromJson(data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<GhnProvince>> getProvinces() async {
    try {
      final response = await _api.getProvinces();
      final data = response.data is Map ? response.data["data"] : response.data;
      return GhnMapper.provinces((data as List).cast<dynamic>());
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<GhnDistrict>> getDistricts(int provinceId) async {
    try {
      final response = await _api.getDistricts(provinceId);
      final data = response.data is Map ? response.data["data"] : response.data;
      return GhnMapper.districts((data as List).cast<dynamic>());
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<GhnWard>> getWards(int districtId) async {
    try {
      final response = await _api.getWards(districtId);
      final data = response.data is Map ? response.data["data"] : response.data;
      return GhnMapper.wards((data as List).cast<dynamic>());
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<GhnServiceOption>> getServices(int toDistrictId) async {
    try {
      final response = await _api.getServices(toDistrictId);
      final data = response.data is Map ? response.data["data"] : response.data;
      return GhnMapper.services((data as List).cast<dynamic>());
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<GhnFee> calculateFee({
    required int orderId,
    required int toDistrictId,
    required String toWardCode,
    required int serviceId,
    required int serviceTypeId,
    int? insuranceValue,
  }) async {
    try {
      final response = await _api.calculateFee({
        "order_id": orderId,
        "to_district_id": toDistrictId,
        "to_ward_code": toWardCode,
        "service_id": serviceId,
        "service_type_id": serviceTypeId,
        "insurance_value": insuranceValue,
      });
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      final data = _extractMap(raw);
      return GhnMapper.fee(data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<GhnShipment> createGhnOrder({
    required int orderId,
    required int toDistrictId,
    required String toWardCode,
    required int serviceId,
    required int serviceTypeId,
    int? insuranceValue,
    String? note,
    String? requiredNote,
  }) async {
    try {
      final response = await _api.createGhnOrder({
        "order_id": orderId,
        "to_district_id": toDistrictId,
        "to_ward_code": toWardCode,
        "service_id": serviceId,
        "service_type_id": serviceTypeId,
        "insurance_value": insuranceValue,
        "note": note,
        "required_note": requiredNote,
      });
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      final data = _extractMap(raw);
      return GhnMapper.shipment(data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<VnpayPaymentUrl> createVnpayPayment({required int orderId}) async {
    try {
      final response = await _api.createVnpayPayment({"order_id": orderId});
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      final data = _extractMap(raw);
      return VnpayMapper.fromJson(data);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
