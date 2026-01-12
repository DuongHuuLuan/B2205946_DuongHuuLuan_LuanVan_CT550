import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount.dart';

abstract class DiscountRepository {
  Future<List<Discount>> getDiscountsForCart({required List<int> categoryIds});
}
