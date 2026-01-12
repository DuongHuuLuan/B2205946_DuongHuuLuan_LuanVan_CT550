import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount.dart';

class DiscountMapper extends Discount {
  DiscountMapper({
    required super.id,
    required super.categoryId,
    required super.name,
    required super.description,
    required super.percent,
    required super.startAt,
    required super.endAt,
    required super.status,
  });

  factory DiscountMapper.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) =>
        value is int ? value : int.tryParse(value?.toString() ?? "") ?? 0;

    double toDouble(dynamic value) =>
        value is double ? value : double.tryParse(value?.toString() ?? "") ?? 0;

    DateTime toDate(dynamic value) {
      if (value is DateTime) return value;
      return DateTime.tryParse(value?.toString() ?? "") ?? DateTime(1970);
    }

    return DiscountMapper(
      id: toInt(json["id"]),
      categoryId: toInt(json["category_id"]),
      name: json["name"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      percent: toDouble(json["percent"]),
      startAt: toDate(json["start_at"]),
      endAt: toDate(json["end_at"]),
      status: json["status"]?.toString() ?? "",
    );
  }
}
