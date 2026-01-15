import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/payment_method.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/vnpay.dart';

abstract class CheckoutRepository {
  Future<List<PaymentMethod>> getPaymentMethods();
  Future<List<DeliveryInfo>> getDeliveryInfos();
  Future<DeliveryInfo> createDeliveryInfo({
    required String name,
    required String phone,
    required String address,
    required int? districtId,
    required String? wardCode,
    bool isDefault = false,
  });

  Future<OrderOut> createOrder(OrderCreate order);

  Future<List<GhnProvince>> getProvinces();
  Future<List<GhnDistrict>> getDistricts(int provinceId);
  Future<List<GhnWard>> getWards(int districtId);
  Future<List<GhnServiceOption>> getServices(int toDistrictId);

  Future<GhnFee> calculateFee({
    required int orderId,
    required int toDistrictId,
    required String toWardCode,
    required int serviceId,
    required int serviceTypeId,
    int? insuranceValue,
  });

  Future<GhnShipment> createGhnOrder({
    required int orderId,
    required int toDistrictId,
    required String toWardCode,
    required int serviceId,
    required int serviceTypeId,
    int? insuranceValue,
    String? note,
    String? requiredNote,
  });

  Future<VnpayPaymentUrl> createVnpayPayment({required int orderId});
}
