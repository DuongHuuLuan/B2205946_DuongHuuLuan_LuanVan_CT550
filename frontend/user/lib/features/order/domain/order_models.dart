class OrderItemCreate {
  final int productDetailId;
  final int quantity;

  const OrderItemCreate({
    required this.productDetailId,
    required this.quantity,
  });
}

class OrderCreate {
  final int deliveryInfoId;
  final int paymentMethodId;
  final List<OrderItemCreate> items;

  const OrderCreate({
    required this.deliveryInfoId,
    required this.paymentMethodId,
    required this.items,
  });
}

class OrderDetailOut {
  final int productDetailId;
  final int quantity;
  final double price;
  final String productName;
  final String? colorName;
  final String? sizeName;
  final String? imageUrl;

  const OrderDetailOut({
    required this.productDetailId,
    required this.quantity,
    required this.price,
    required this.productName,
    this.colorName,
    this.sizeName,
    this.imageUrl,
  });
}

class OrderOut {
  final int id;
  final String status;
  final DateTime? createdAt;
  final double total;
  final List<OrderDetailOut> orderDetails;
  final String? discountCode;

  const OrderOut({
    required this.id,
    required this.status,
    this.createdAt,
    this.total = 0,
    this.orderDetails = const [],
    this.discountCode,
  });
}
