import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category.dart';

class CategoryMapper extends Category {
  CategoryMapper({required super.id, required super.name});

  factory CategoryMapper.fromJson(Map<String, dynamic> json) {
    return CategoryMapper(id: json['id'].toString(), name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "name": name};
  }
}
