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
}
