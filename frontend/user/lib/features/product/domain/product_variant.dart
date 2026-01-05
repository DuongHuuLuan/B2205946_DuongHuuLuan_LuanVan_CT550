class ProductVariant {
  final String id;
  final String colorId;
  final String colorName;
  final String colorHex;
  final String sizeId;
  final String size;
  final int stockQuantity;
  final double price;
  // final double? purchasePrice;

  ProductVariant({
    required this.id,
    required this.colorId,
    required this.colorName,
    required this.colorHex,
    required this.sizeId,
    required this.size,
    required this.stockQuantity,
    required this.price,
    // required this.purchasePrice,
  });
}
