import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/order_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/delivery_info_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/ghn_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/order_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/payment_method_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/data/models/vnpay_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/payment_method.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/vnpay.dart';
import 'package:dio/dio.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderApi _api;
  OrderRepositoryImpl(this._api);

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
  Future<List<OrderOut>> getOrderHistory() async {
    try {
      final reponse = await _api.getOrderHistory();
      final List<dynamic> data = reponse.data;
      return data.map((e) => OrderMapper.fromJson(e)).toList();
    } on DioException catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  @override
  Future<OrderOut> getOrderDetail(int orderId) async {
    try {
      final response = await _api.getOrderDetail(orderId);
      return OrderMapper.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  @override
  Future<OrderOut> confirmDelivery(int orderId) async {
    try {
      final response = await _api.confirmDelivery(orderId);
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;
      final data = _extractMap(raw);
      return OrderMapper.fromJson(data);
    } on DioException catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  @override
  Future<void> cancelOrder(int orderId) async {
    try {
      await _api.cancelOrder(orderId);
    } on DioException catch (error) {
      throw ErrorHandler.handle(error);
    }
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
        "discount_ids": order.discountIds,
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
    int? orderId,
    required int toDistrictId,
    required String toWardCode,
    required int serviceId,
    required int serviceTypeId,
    int? insuranceValue,
    required int weight,
  }) async {
    try {
      final payload = <String, dynamic>{
        "to_district_id": toDistrictId,
        "to_ward_code": toWardCode.trim(),
        "insurance_value": insuranceValue,
        "weight": weight,
        "Weight": weight,
      };
      if (serviceId > 0) {
        payload["service_id"] = serviceId;
      }
      if (serviceTypeId > 0) {
        payload["service_type_id"] = serviceTypeId;
      }
      if (orderId != null) {
        payload["order_id"] = orderId;
      }
      final response = await _api.calculateFee(payload);
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
    required int weight,
    int? insuranceValue,
    String? note,
    String? requiredNote,
  }) async {
    try {
      final payload = <String, dynamic>{
        "order_id": orderId,
        "to_district_id": toDistrictId,
        "to_ward_code": toWardCode.trim(),
        "insurance_value": insuranceValue,
        "weight": weight,
        "Weight": weight,
        "note": note,
        "required_note": requiredNote,
      };
      if (serviceId > 0) {
        payload["service_id"] = serviceId;
      }
      if (serviceTypeId > 0) {
        payload["service_type_id"] = serviceTypeId;
      }
      final response = await _api.createGhnOrder(payload);
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
