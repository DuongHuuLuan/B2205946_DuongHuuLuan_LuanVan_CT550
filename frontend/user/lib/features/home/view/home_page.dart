import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Import viewmodels và widgets của bạn
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/presentation/viewmodel/category_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/category_strip.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/circle_icon_button.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/hero_carousel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/home_drawer.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/viewmodel/product_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/widget/product_sections.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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

    // Lấy ColorScheme
    final colorScheme = Theme.of(context).colorScheme;

    final Map<int, String> categoryThumbs = {};
    for (final p in productVm.products) {
      if (p.images.isEmpty) continue;
      categoryThumbs.putIfAbsent(p.categoryId, () => p.images.first.url);
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const HomeDrawer(),
      backgroundColor: colorScheme.surface, // Đồng bộ nền trang chủ
      body: CustomScrollView(
        slivers: [
          _HomeSliverAppBar(
            onCart: () => context.go("/cart"),
            onSearch: () {},
            onProfile: () async => auth.logout(),
            onMenu: () => _scaffoldKey.currentState?.openDrawer(),
          ),

          const SliverToBoxAdapter(
            child: HeroCarousel(
              imageUrls: [
                "assets/images/banner1.webp",
                "assets/images/banner2.webp",
                "assets/images/banner3.webp",
                "assets/images/banner4.webp",
              ],
              height: 220,
            ),
          ),

          SliverToBoxAdapter(
            child: CategoryStrip(
              categories: categoryVm.categories,
              thumbnails: categoryThumbs,
              onTap: (c) => context.go("/products/categories/${c.id}"),
            ),
          ),

          if (productVm.isLoading && productVm.products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
              ),
            )
          else if (productVm.errorMessage != null && productVm.products.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  productVm.errorMessage!,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: ProductSections(
                categories: categoryVm.categories,
                products: productVm.products,
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeSliverAppBar extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onCart;
  final VoidCallback onSearch;
  final VoidCallback onMenu;

  const _HomeSliverAppBar({
    required this.onProfile,
    required this.onCart,
    required this.onSearch,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);

    // Tính toán kích thước như cũ
    final statusBarH = media.padding.top;
    final w = media.size.width;
    final double logoMax = (w * 0.14).clamp(48.0, 58.0);
    final double logoMin = (w * 0.115).clamp(40.0, 48.0);
    final double topPadMax = (w * 0.030).clamp(8.0, 16.0);
    final double topPadMin = 0.0;
    final double bottomPadMax = (w * 0.020).clamp(6.0, 12.0);
    final double expandedH = statusBarH + logoMax + topPadMax + bottomPadMax;
    final double collapsedH = statusBarH + logoMin + topPadMin;

    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: colorScheme.primary, // Màu thanh Appbar từ Theme
      expandedHeight: expandedH,
      collapsedHeight: collapsedH,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final t =
              ((constraints.maxHeight - collapsedH) / (expandedH - collapsedH))
                  .clamp(0.0, 1.0);
          final logoSize = lerpDouble(logoMin, logoMax, t)!;
          final topPad = lerpDouble(topPadMin, topPadMax, t)!;
          final bottomPad = lerpDouble(0.0, bottomPadMax, t)!;

          return Container(
            color: colorScheme.primary, // Đồng nhất màu nền
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(
                  top: topPad,
                  left: 10,
                  right: 10,
                  bottom: bottomPad,
                ),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage("assets/images/logo.webp"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Nút bấm - Giả sử CircleIconButton đã dùng colorScheme bên trong
                    CircleIconButton(icon: Icons.person, onTap: onProfile),
                    const SizedBox(width: 8),
                    CircleIconButton(icon: Icons.shopping_bag, onTap: onCart),
                    const SizedBox(width: 8),
                    CircleIconButton(icon: Icons.search, onTap: onSearch),
                    const SizedBox(width: 8),
                    CircleIconButton(icon: Icons.menu, onTap: onMenu),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
