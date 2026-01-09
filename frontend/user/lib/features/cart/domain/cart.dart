class Cart {
  final int id;
  final List<CartItem> items;
  final int totalQuantity;
  final num totalPrice;

  const Cart({
    required this.id,
    required this.items,
    required this.totalQuantity,
    required this.totalPrice,
  });
  bool get isEmpty => items.isEmpty;
}

class CartItem {
  final int id;
  final int variantId;
  final String title;
  final String? iamgeUrl;
  final num unitPrice;
  final int quantity;

  const CartItem({
    required this.id,
    required this.variantId,
    required this.title,
    this.iamgeUrl,
    required this.unitPrice,
    required this.quantity,
    String? imageUrl,
  });

  num get lineTotal => unitPrice * quantity;
}
