import 'package:b2205946_duonghuuluan_luanvan/core/constants/api_endpoints.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class CheckoutApi {
  Future<Response> getPaymentMethods() {
    return DioClient.instance.get(ApiEndpoints.paymentMethods);
  }

  Future<Response> createDeliveryInfo(Map<String, dynamic> data) {
    return DioClient.instance.post(ApiEndpoints.delivery);
  }

  Future<Response> getDeliveryInfos() {
    return DioClient.instance.get(ApiEndpoints.delivery);
  }

  Future<Response> createOrder(Map<String, dynamic> data) {
    return DioClient.instance.post(ApiEndpoints.orders, data: data);
  }

  Future<Response> getProvinces() {
    return DioClient.instance.get(ApiEndpoints.ghnProvinces);
  }

  Future<Response> getDistricts(int provinceId) {
    return DioClient.instance.get(ApiEndpoints.ghnDistricts(provinceId));
  }

  Future<Response> getWards(int districtId) {
    return DioClient.instance.get(ApiEndpoints.ghnWards(districtId));
  }

  Future<Response> getServices(int toDistrictId) {
    return DioClient.instance.get(
      ApiEndpoints.ghnServices,
      queryParameters: {"to_district_id": toDistrictId},
    );
  }

  Future<Response> calculateFee(Map<String, dynamic> data) {
    return DioClient.instance.post(ApiEndpoints.ghnFee, data: data);
  }

  Future<Response> createGhnOrder(Map<String, dynamic> data) {
    return DioClient.instance.post(ApiEndpoints.ghnCreateOrder, data: data);
  }

  Future<Response> createVnpayPayment(Map<String, dynamic> data) {
    return DioClient.instance.post(ApiEndpoints.vnpayCreatePayment, data: data);
  }
}
