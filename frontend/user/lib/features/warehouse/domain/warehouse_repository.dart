abstract class WarehouseRepository {
  Future<int> getTotalStock({
    required int productId,
    required int colorId,
    required int sizeId,
  });
}
