import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';

class Cart {
  final int id;
  final int userId;
  final List<CartDetail> cartDetails;
  final double totalPrice;
  final bool canCheckout;

  const Cart({
    required this.id,
    required this.userId,
    required this.cartDetails,
    required this.totalPrice,
    required this.canCheckout,
  });

  bool get isEmpty => cartDetails.isEmpty;
  bool get hasInvalidItems =>
      cartDetails.any((element) => !element.canCheckout);
}

class CartDetail {
  final int id;
  final int productDetailId;
  final int? designId;
  final String? designName;
  final String? designPreviewImageUrl;
  final int quantity;
  final ProductDetail productDetail;

  final bool isActive;
  final int availableStock;
  final String cartStatus;
  final String? statusMessage;
  final bool canCheckout;

  const CartDetail({
    required this.id,
    required this.productDetailId,
    this.designId,
    this.designName,
    this.designPreviewImageUrl,
    required this.quantity,
    required this.productDetail,
    required this.isActive,
    required this.availableStock,
    required this.cartStatus,
    required this.statusMessage,
    required this.canCheckout,
  });

  double get lineTotal => productDetail.price * quantity;
  bool get hasDesign => (designId ?? 0) > 0;

  bool get isInactive => cartStatus == "inactive";
  bool get isOutOfStock => cartStatus == "out_of_stock";
  bool get isInsufficientStock => cartStatus == "insufficient_stock";
  bool get isOk => cartStatus == "ok";
  bool get isLocked => !canCheckout;
}
