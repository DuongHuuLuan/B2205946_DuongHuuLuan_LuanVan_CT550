import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category_repository.dart';
import 'package:flutter/material.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repository;
  CategoryViewModel(this._repository);

  bool isLoading = false;
  String? errorMessage;
  List<Category> categories = [];

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      categories = await _repository.getAll();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Category?> getById(String id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<List<Category>?> getAllProudctByCategoryId(String categoryId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await _repository.getAllProudctByCategoryId(categoryId);
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
