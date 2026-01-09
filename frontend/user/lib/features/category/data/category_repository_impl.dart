import 'package:b2205946_duonghuuluan_luanvan/core/network/error_handler.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/data/category_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/data/model/category_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category_repository.dart';
import 'package:dio/dio.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryApi _api;
  CategoryRepositoryImpl(this._api);

  @override
  Future<List<Category>> getAll() async {
    try {
      final response = await _api.getAll();
      final list = (response.data as List).cast<Map<String, dynamic>>();
      return list.map(CategoryMapper.fromJson).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<Category> getById(int id) async {
    try {
      final response = await _api.getById(id);
      return CategoryMapper.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<List<Category>> getAllProudctByCategoryId(int categoryId) async {
    try {
      final response = await _api.getAllProudctByCategoryId(categoryId);
      final list = (response.data as List).cast<Map<String, dynamic>>();
      return list.map(CategoryMapper.fromJson).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}

