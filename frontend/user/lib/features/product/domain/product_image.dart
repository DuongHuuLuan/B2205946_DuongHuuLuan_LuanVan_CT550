class ProductImage {
  final int id;
  final String url;
  final String publicId;
  final int? colorId;

  ProductImage({
    required this.id,
    required this.url,
    required this.publicId,
    this.colorId,
  });
}
