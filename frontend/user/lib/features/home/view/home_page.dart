import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/presentation/viewmodel/category_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/category_strip.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/hero_carousel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/home_app_bar.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/viewmodel/product_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/widget/product_sections.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<ProductViewmodel>().getAllProduct();
      await context.read<CategoryViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewmodel>();
    final productVm = context.watch<ProductViewmodel>();
    final categoryVm = context.watch<CategoryViewModel>();

    // categoryId -> ảnh đại diện (ảnh đầu của sản phẩm thuộc category)
    final Map<String, String> categoryThumbs = {};
    for (final p in productVm.products) {
      if (p.images.isEmpty) continue;
      categoryThumbs.putIfAbsent(p.categoryId, () => p.images.first.url);
    }

    return Scaffold(
      appBar: HomeAppBar(
        onCart: () {},
        onMenu: () {},
        onProfile: () async => auth.logout(),
        onSearch: () {},
      ),
      body: ListView(
        children: [
          const HeroCarousel(
            imageUrls: [
              "assets/images/banner1.webp",
              "assets/images/banner2.webp",
              "assets/images/banner3.webp",
              "assets/images/banner4.webp",
            ],
            height: 220,
          ),

          CategoryStrip(
            categories: categoryVm.categories,
            thumbnails: categoryThumbs,
            onTap: (c) {},
          ),
          if (productVm.isLoading && productVm.products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (productVm.errorMessage != null && productVm.products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(productVm.errorMessage!),
            )
          else
            ProductSections(
              categories: categoryVm.categories,
              products: productVm.products,
            ),
        ],
      ),
    );
  }
}
