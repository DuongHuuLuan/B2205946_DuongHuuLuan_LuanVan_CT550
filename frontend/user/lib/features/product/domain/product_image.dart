class ProductImage {
  final int id;
  final String url;
  final String publicId;
  final int? colorId;
  final String? viewImageKey;

  ProductImage({
    required this.id,
    required this.url,
    required this.publicId,
    this.colorId,
    this.viewImageKey,
  });
}

const List<String> orderedViewImageKeys = <String>[
  'front',
  'front_right',
  'right',
  'back',
  'left',
  'front_left',
];

int viewImageKeyPriority(String? value) {
  final key = (value ?? '').trim();
  if (key.isEmpty) return orderedViewImageKeys.length + 1;
  final index = orderedViewImageKeys.indexOf(key);
  return index >= 0 ? index : orderedViewImageKeys.length;
}

String viewImageKeyLabel(String? value) {
  switch ((value ?? '').trim()) {
    case 'front':
      return 'Mat truoc';
    case 'front_right':
      return 'Cheo phai';
    case 'right':
      return 'Ben phai';
    case 'back':
      return 'Mat sau';
    case 'left':
      return 'Ben trai';
    case 'front_left':
      return 'Cheo trai';
    default:
      return 'Anh mac dinh';
  }
}
