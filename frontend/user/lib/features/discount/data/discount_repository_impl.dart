import 'package:dio/dio.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/data/discount_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/data/models/discount_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount_repository.dart';

class DiscountRepositoryImpl implements DiscountRepository {
  final DiscountApi _api;
  DiscountRepositoryImpl(this._api);

  @override
  Future<List<Discount>> getDiscountsForCart({
    required List<int> categoryIds,
  }) async {
    try {
      final response = await _api.getDiscountsForCart(
        categoryIds: categoryIds,
      );
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;

      if (raw is List) {
        final list = raw.cast<Map<String, dynamic>>();
        return list.map(DiscountMapper.fromJson).toList();
      }
      return [];
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
