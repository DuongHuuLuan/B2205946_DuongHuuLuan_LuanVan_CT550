import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/view/login_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/view/register_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/cart_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/home_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/others/about/presentation/view/about_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/view/product_catagory_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/view/product_detail_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/view/product_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';

class AppRouter {
  static GoRouter createRouter(AuthViewmodel authVM) {
    return GoRouter(
      initialLocation: "/",
      refreshListenable: authVM,
      redirect: (context, state) {
        // Ä‘á»£i AuthViewModel náº¡p dá»¯ liá»‡u tá»« SecureStorage trÆ°á»›c
        if (!authVM.isInitialized) return "/splash";

        final bool loggedIn = authVM.isAuthenticated;
        final String location = state.matchedLocation;

        final bool isAtLogin = location == "/login";
        final bool isAtRegister = location == "/register";
        final bool isAtSplash = location == "/splash";

        // 2. Náº¿u CHÆ¯A Ä‘Äƒng nháº­p
        if (!loggedIn) {
          // Náº¿u Ä‘ang á»Ÿ Login hoáº·c Register thÃ¬ cho á»Ÿ láº¡i, ngÆ°á»£c láº¡i Ä‘áº©y vá» Login
          if (isAtLogin || isAtRegister) return null;
          return "/login";
        }

        // 3. Náº¿u ÄÃƒ Ä‘Äƒng nháº­p
        if (loggedIn) {
          // Náº¿u Ä‘ang á»Ÿ Login, Register hoáº·c Splash thÃ¬ Ä‘áº©y vÃ o Home
          if (isAtLogin || isAtRegister || isAtSplash) return "/";
        }

        // Má»i trÆ°á»ng há»£p khÃ¡c cho phÃ©p Ä‘i tiáº¿p
        return null;
      },
      routes: [
        GoRoute(path: "/login", builder: (context, state) => const LoginPage()),
        GoRoute(
          path: "/register",
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(path: "/", builder: (context, state) => const HomePage()),

        GoRoute(
          path: "/splash",
          builder: (context, state) => Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.onPrimary),
            ),
          ),
        ),

        GoRoute(
          path: "/products/categories",
          builder: (context, state) {
            return const ProductCatagoryPage();
          },
        ),

        GoRoute(
          path: "/products/categories/:id",
          builder: (context, state) {
            final categoryId = int.parse(state.pathParameters["id"]!);
            return ProductCatagoryPage(categoryId: categoryId);
          },
        ),

        GoRoute(
          path: "/products",
          builder: (context, state) => const ProductPage(),
        ),
        GoRoute(
          path: "/products/:id",
          builder: (context, state) {
            return ProductDetailPage(
              productId: int.parse(state.pathParameters["id"]!),
            );
          },
        ),

        GoRoute(path: "/cart", builder: (context, state) => const CartPage()),

        GoRoute(path: "/about", builder: (context, state) => const AboutPage()),
      ],
    );
  }
}
