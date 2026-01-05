import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAll();
  Future<Category> getById(String id);
}
