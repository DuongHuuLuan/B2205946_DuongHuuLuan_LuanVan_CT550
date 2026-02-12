import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/delivery_info.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/order_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/payment_method.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/domain/vnpay.dart';
import 'package:flutter/material.dart';

class OrderViewmodel extends ChangeNotifier {
  final OrderRepository _repository;
  OrderViewmodel(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  int _shippingRequestToken = 0;
  int _feeRequestToken = 0;

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
  int? lastOrderId;

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
    _shippingRequestToken++;
    _feeRequestToken++;
    _errorMessage = null;

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
    _shippingRequestToken++;
    _feeRequestToken++;
    _errorMessage = null;

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
    _feeRequestToken++;
    _errorMessage = null;
    selectedWard = ward;
    feeTotal = null;
    notifyListeners();
    _refreshFeeIfReady();
  }

  void selectService(GhnServiceOption? service) {
    _feeRequestToken++;
    _errorMessage = null;
    selectedService = service;
    feeTotal = null;
    notifyListeners();
    _refreshFeeIfReady();
  }

  Future<void> selectDelivery(DeliveryInfo? delivery) async {
    _shippingRequestToken++;
    _feeRequestToken++;
    selectedDelivery = delivery;

    if (delivery == null) {
      useSavedAddress = false;
      selectedDistrict = null;
      selectedWard = null;
      selectedService = null;
      services = [];
      feeTotal = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    useSavedAddress = true;
    await _applyDeliveryShipping(delivery);
    notifyListeners();
  }

  Future<void> _applyDeliveryShipping(DeliveryInfo delivery) async {
    final requestToken = ++_shippingRequestToken;
    final districtId = delivery.districtId;
    final wardCode = delivery.wardCode?.trim() ?? "";

    selectedDistrict = null;
    selectedWard = null;
    selectedService = null;
    services = [];
    feeTotal = null;

    if (districtId == null || districtId <= 0 || wardCode.isEmpty) {
      _errorMessage =
          "Địa chỉ đã lưu thiếu district/ward. Vui lòng tạo lại địa chỉ.";
      notifyListeners();
      return;
    }

    selectedDistrict = GhnDistrict(
      districtId: districtId,
      districtName: "Đã lưu",
    );
    selectedWard = GhnWard(wardCode: wardCode, wardName: "Đã lưu");
    notifyListeners();

    try {
      final loadedServices = await _repository.getServices(districtId);
      if (requestToken != _shippingRequestToken) {
        return;
      }

      services = loadedServices;
      selectedService = services.isNotEmpty ? services.first : null;
      if (selectedService == null) {
        _errorMessage = "Không lấy được dịch vụ GHN cho địa chỉ này.";
        notifyListeners();
        return;
      }

      _errorMessage = null;
      notifyListeners();
      _refreshFeeIfReady();
    } catch (e) {
      if (requestToken != _shippingRequestToken) {
        return;
      }
      selectedService = null;
      services = [];
      feeTotal = null;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> calculateFee({int? insuranceValue}) async {
    final districtId = selectedDistrict?.districtId ?? 0;
    final wardCode = selectedWard?.wardCode.trim() ?? "";
    final serviceId = selectedService?.serviceId ?? 0;
    final serviceTypeId = selectedService?.serviceTypeId ?? 0;

    if (districtId <= 0 || wardCode.isEmpty || serviceId <= 0) {
      _feeRequestToken++;
      feeTotal = null;
      notifyListeners();
      return;
    }

    final requestToken = ++_feeRequestToken;
    try {
      const int defaultWeight = 1000;
      final fee = await _repository.calculateFee(
        toDistrictId: districtId,
        toWardCode: wardCode,
        serviceId: serviceId,
        serviceTypeId: serviceTypeId,
        insuranceValue: insuranceValue,
        weight: defaultWeight,
      );
      if (requestToken != _feeRequestToken) {
        return;
      }
      feeTotal = fee.total;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (requestToken != _feeRequestToken) {
        return;
      }
      feeTotal = null;
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
      lastOrderId = order.id;

      await _repository.createGhnOrder(
        orderId: order.id,
        toDistrictId: selectedDistrict!.districtId,
        toWardCode: selectedWard!.wardCode,
        serviceId: selectedService!.serviceId,
        serviceTypeId: selectedService!.serviceTypeId,
        insuranceValue: null,
        note: note,
        requiredNote: normalizedRequiredNote,
        weight: 1000,
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

  void _refreshFeeIfReady() {
    final districtId = selectedDistrict?.districtId ?? 0;
    final wardCode = selectedWard?.wardCode.trim() ?? "";
    final serviceId = selectedService?.serviceId ?? 0;

    if (districtId <= 0 || wardCode.isEmpty || serviceId <= 0) {
      return;
    }
    final insurance = _estimateInsuranceValue();
    calculateFee(insuranceValue: insurance);
  }

  int _estimateInsuranceValue() {
    double total = 0;
    for (final item in cartDetails) {
      total += item.lineTotal;
    }
    if (total <= 0) return 0;
    return total.ceil();
  }
}
