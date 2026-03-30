import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/helmet_designer/domain/helmet_designer_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfileDesignsPage extends StatefulWidget {
  const ProfileDesignsPage({super.key});

  @override
  State<ProfileDesignsPage> createState() => _ProfileDesignsPageState();
}

class _ProfileDesignsPageState extends State<ProfileDesignsPage> {
  late Future<List<HelmetDesign>> _designsFuture;

  @override
  void initState() {
    super.initState();
    _designsFuture = context.read<HelmetDesignerRepository>().getMyDesigns();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: AppBar(
        title: const Text("Thiết kế của tôi"),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go("/");
            }
          },
          icon: Icon(Icons.arrow_back, color: AppColors.onPrimary),
        ),
      ),
      body: FutureBuilder<List<HelmetDesign>>(
        future: _designsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final designs = snapshot.data ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.75,
            ),
            itemCount: designs.length,
            itemBuilder: (context, index) {
              final design = designs[index];

              return _DesignCard(
                design: design,
                onTap: () {
                  context.push("/helmet-designer?designId=${design.id}");
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final HelmetDesign design;
  final VoidCallback onTap;

  const _DesignCard({required this.design, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  design.helmetBaseImageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.helmetName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ngày lưu: ${design.createdAt}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
