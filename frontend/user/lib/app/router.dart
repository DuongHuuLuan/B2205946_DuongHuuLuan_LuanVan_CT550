import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/view/login_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/view/register_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/presentation/view/category_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/home_page.dart';
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
        // đợi AuthViewModel nạp dữ liệu từ SecureStorage trước
        if (!authVM.isInitialized) return "/splash";

        final bool loggedIn = authVM.isAuthenticated;
        final String location = state.matchedLocation;

        final bool isAtLogin = location == "/login";
        final bool isAtRegister = location == "/register";
        final bool isAtSplash = location == "/splash";

        // 2. Nếu CHƯA đăng nhập
        if (!loggedIn) {
          // Nếu đang ở Login hoặc Register thì cho ở lại, ngược lại đẩy về Login
          if (isAtLogin || isAtRegister) return null;
          return "/login";
        }

        // 3. Nếu ĐÃ đăng nhập
        if (loggedIn) {
          // Nếu đang ở Login, Register hoặc Splash thì đẩy vào Home
          if (isAtLogin || isAtRegister || isAtSplash) return "/";
        }

        // Mọi trường hợp khác cho phép đi tiếp
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
          path: "/categories",
          builder: (context, state) {
            return const CategoryPage();
          },
        ),

        GoRoute(
          path: "/products",
          builder: (context, state) => const ProductPage(),
        ),
        GoRoute(
          path: "/products/:id",
          builder: (context, state) {
            return ProductDetailPage(productId: state.pathParameters["id"]!);
          },
        ),
      ],
    );
  }
}
