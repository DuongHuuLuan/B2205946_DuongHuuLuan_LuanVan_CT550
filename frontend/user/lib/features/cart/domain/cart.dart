import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_detail.dart';

class Cart {
  final int id;
  final int userId;
  final List<CartDetail> cartDetails;
  final double totalPrice;

  const Cart({
    required this.id,
    required this.userId,
    required this.cartDetails,
    required this.totalPrice,
  });

  bool get isEmpty => cartDetails.isEmpty;
}

class CartDetail {
  final int id;
  final int productDetailId;
  final int? designId;
  final String? designName;
  final String? designPreviewImageUrl;
  final int quantity;
  final ProductDetail productDetail;

  const CartDetail({
    required this.id,
    required this.productDetailId,
    this.designId,
    this.designName,
    this.designPreviewImageUrl,
    required this.quantity,
    required this.productDetail,
  });

  double get lineTotal => productDetail.price * quantity;
  bool get hasDesign => (designId ?? 0) > 0;
}
