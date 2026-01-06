class ProductImage {
  final String id;
  final String url;
  final String publicId;
  final String? colorId;

  ProductImage({
    required this.id,
    required this.url,
    required this.publicId,
    this.colorId,
  });
}
