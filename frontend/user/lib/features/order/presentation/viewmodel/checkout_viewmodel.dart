import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/checkout_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/payment_method.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/vnpay.dart';
import 'package:flutter/material.dart';

class CheckoutViewmodel extends ChangeNotifier {
  final CheckoutRepository _repository;
  CheckoutViewmodel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CartDetail> cartDetails = [];
  List<PaymentMethod> paymentMethods = [];
  PaymentMethod? selectedPayment;

  List<GhnProvince> provinces = [];
  List<GhnDistrict> districts = [];
  List<GhnWard> wards = [];
  List<GhnServiceOption> services = [];

  GhnProvince? selectedProvince;
  GhnDistrict? selectedDistrict;
  GhnWard? selectedWard;
  GhnServiceOption? selectedService;

  List<DeliveryInfo> deliveries = [];
  DeliveryInfo? selectedDelivery;
  bool useSavedAddress = true;

  double? feeTotal;

  void setCartDetails(List<CartDetail> details) {
    cartDetails = details;
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      paymentMethods = await _repository.getPaymentMethods();
      if (paymentMethods.isNotEmpty) {
        selectedPayment = paymentMethods.first;
      }
      deliveries = await _repository.getDeliveryInfos();
      if (deliveries.isNotEmpty) {
        selectedDelivery = deliveries.first;
        useSavedAddress = true;
        await _applyDeliveryShipping(selectedDelivery!);
      } else {
        useSavedAddress = false;
      }

      provinces = await _repository.getProvinces();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectProvince(GhnProvince? province) async {
    selectedProvince = province;
    selectedDistrict = null;
    selectedWard = null;
    selectedService = null;
    districts = [];
    wards = [];
    services = [];
    feeTotal = null;
    notifyListeners();
    if (province == null) return;
    try {
      districts = await _repository.getDistricts(province.provinceId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> selectDistrict(GhnDistrict? district) async {
    selectedDistrict = district;
    selectedWard = null;
    selectedService = null;
    wards = [];
    services = [];
    feeTotal = null;
    notifyListeners();
    if (district == null) return;
    try {
      wards = await _repository.getWards(district.districtId);
      services = await _repository.getServices(district.districtId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void selectWard(GhnWard? ward) {
    selectedWard = ward;
    feeTotal = null;
    notifyListeners();
  }

  void selectService(GhnServiceOption? service) {
    selectedService = service;
    feeTotal = null;
    notifyListeners();
  }

  Future<void> selectDelivery(DeliveryInfo? delivery) async {
    selectedDelivery = delivery;
    if (delivery == null) {
      useSavedAddress = false;
      selectedDistrict = null;
      selectedWard = null;
      selectedService = null;
      services = [];
      feeTotal = null;
      notifyListeners();
      return;
    }
    useSavedAddress = true;
    await _applyDeliveryShipping(delivery);
    notifyListeners();
  }

  Future<void> _applyDeliveryShipping(DeliveryInfo delivery) async {
    if (delivery.districtId == null || delivery.wardCode == null) {
      return;
    }
    selectedDistrict = GhnDistrict(
      districtId: delivery.districtId!,
      districtName: "Da luu",
    );
    selectedWard = GhnWard(wardCode: delivery.wardCode!, wardName: "Da luu");
    services = await _repository.getServices(delivery.districtId!);
    if (services.isNotEmpty) {
      selectedService = services.first;
    }
  }

  Future<void> calculateFee(int orderId, {int? insuranceValue}) async {
    if (selectedDistrict == null ||
        selectedWard == null ||
        selectedService == null) {
      return;
    }
    try {
      final fee = await _repository.calculateFee(
        orderId: orderId,
        toDistrictId: selectedDistrict!.districtId,
        toWardCode: selectedWard!.wardCode,
        serviceId: selectedService!.serviceId,
        serviceTypeId: selectedService!.serviceTypeId,
        insuranceValue: insuranceValue,
      );
      feeTotal = fee.total;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<VnpayPaymentUrl?> submitOrder({
    required String name,
    required String phone,
    required String address,
    String? note,
    String? requiredNote,
  }) async {
    if (selectedPayment == null ||
        selectedDistrict == null ||
        selectedWard == null ||
        selectedService == null) {
      _errorMessage = "Vui lòng chọn đầy đủ địa chỉ và dịch vụ GHN";
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final normalizedRequiredNote = _normalizeRequiredNote(requiredNote);
      final deliveryInfo = useSavedAddress && selectedDelivery != null
          ? selectedDelivery!
          : await _repository.createDeliveryInfo(
              name: name,
              phone: phone,
              address: address,
              districtId: selectedDistrict!.districtId,
              wardCode: selectedWard!.wardCode,
            );

      final order = await _repository.createOrder(
        OrderCreate(
          deliveryInfoId: deliveryInfo.id,
          paymentMethodId: selectedPayment!.id,
          items: cartDetails
              .map(
                (item) => OrderItemCreate(
                  productDetailId: item.productDetailId,
                  quantity: item.quantity,
                ),
              )
              .toList(),
        ),
      );

      await _repository.createGhnOrder(
        orderId: order.id,
        toDistrictId: selectedDistrict!.districtId,
        toWardCode: selectedWard!.wardCode,
        serviceId: selectedService!.serviceId,
        serviceTypeId: selectedService!.serviceTypeId,
        insuranceValue: null,
        note: note,
        requiredNote: normalizedRequiredNote,
      );

      final lowerName = selectedPayment!.name.toLowerCase();
      if (lowerName.contains("vnpay")) {
        return await _repository.createVnpayPayment(orderId: order.id);
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _normalizeRequiredNote(String? value) {
    const valid = {"KHONGCHOXEMHANG", "CHOXEMHANGKHONGTHU", "CHOTHUHANG"};
    if (value != null && valid.contains(value)) {
      return value;
    }
    return "KHONGCHOXEMHANG";
  }
}
