import 'package:dio/dio.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/warehouse/data/warehouse_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/warehouse/domain/warehouse_repository.dart';

class WarehouseRepositoryImpl extends WarehouseRepository {
  final WarehouseApi _api;
  WarehouseRepositoryImpl(this._api);

  @override
  Future<int> getTotalStock({
    required int productId,
    required int colorId,
    required int sizeId,
  }) async {
    try {
      final response = await _api.getTotalStock(
        productId: productId,
        colorId: colorId,
        sizeId: sizeId,
      );
      final raw = response.data is Map
          ? (response.data["data"] ?? response.data)
          : response.data;

      if (raw is int) return raw;
      if (raw is String) return int.tryParse(raw) ?? 0;
      if (raw is Map) {
        final value = raw["total_quantity"] ?? 0;
        if (value is int) return value;
        return int.tryParse(value.toString()) ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
