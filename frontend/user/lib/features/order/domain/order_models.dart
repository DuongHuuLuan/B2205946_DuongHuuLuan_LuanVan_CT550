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

class OrderOut {
  final int id;
  final String status;
  final DateTime? createdAt;
  final double total;

  const OrderOut({
    required this.id,
    required this.status,
    this.createdAt,
    this.total = 0,
  });
}
