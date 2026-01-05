import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category.dart';

class CategoryStrip extends StatelessWidget {
  final List<Category> categories;
  final Map<String, String> thumbnails; // categoryId -> imageUrl
  final void Function(Category c)? onTap;

  const CategoryStrip({
    super.key,
    required this.categories,
    required this.thumbnails,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Container(
      color: const Color(0xFF070C14),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((c) {
            final thumb = thumbnails[c.id];
            return Container(
              width: 180,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onTap?.call(c),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: thumb != null && thumb.isNotEmpty
                            ? Image.network(thumb, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.black38,
                                ),
                              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFD4AF37), width: 1),
                        ),
                      ),
                      child: Text(
                        c.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
