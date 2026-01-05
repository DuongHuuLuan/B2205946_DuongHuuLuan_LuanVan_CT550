import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/hero_carousel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/widget/home_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AuthViewmodel>();
    return Scaffold(
      appBar: HomeAppBar(
        onCart: () {},
        onMenu: () {},
        onProfile: () {},
        onSearch: () {},
      ),
      body: ListView(
        children: [
          HeroCarousel(
            imageUrls: [
              "assets/images/banner1.webp",
              "assets/images/banner2.webp",
              "assets/images/banner3.webp",
              "assets/images/banner4.webp",
            ],
            height: 220,
          ),
        ],
      ),
    );
  }
}
