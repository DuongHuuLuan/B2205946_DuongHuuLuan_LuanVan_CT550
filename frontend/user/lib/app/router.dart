import 'package:b2205946_duonghuuluan_luanvan/app/theme/colors.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/view/login_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/view/register_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/view/cart_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/home/view/home_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/others/about/presentation/view/about_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/view/product_catagory_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/view/product_detail_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/view/product_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/order/presentation/view/order_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/profile/presentation/view/profile_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/storage/secure_storage.dart';

class AppRouter {
  static bool _isRestored = false;

  static GoRouter createRouter(AuthViewmodel authVM) {
    final storage = SecureStorage();

    return GoRouter(
      initialLocation: "/",
      refreshListenable: authVM,
      redirect: (context, state) async {
        final String location = state.matchedLocation;
        final String fullLocation = state.uri.toString();

        // 1. Kiểm tra trạng thái khởi tạo
        if (!authVM.isInitialized) return "/splash";

        final bool loggedIn = authVM.isAuthenticated;
        final bool isAtAuth =
            location == "/login" ||
            location == "/register" ||
            location == "/splash";

        // 2. Nếu chưa đăng nhập
        if (!loggedIn) {
          _isRestored = false;
          // Nếu đang ở login/register thì cho phép ở lại, ngược lại ép về login
          return (location == "/login" || location == "/register")
              ? null
              : "/login";
        }

        // 3. Nếu đã đăng nhập
        if (loggedIn) {
          if (!_isRestored || isAtAuth) {
            _isRestored = true;

            try {
              // Thêm timeout hoặc try-catch để tránh treo khi đọc storage lỗi
              final lastRoute = await storage.getLastRoute().timeout(
                const Duration(seconds: 2),
                onTimeout: () => null,
              );

              if (lastRoute != null &&
                  lastRoute.isNotEmpty &&
                  lastRoute != "/" &&
                  lastRoute != location) {
                return lastRoute;
              }
            } catch (e) {
              debugPrint("Router Error: Không thể khôi phục route cũ: $e");
            }

            // Nếu đang kẹt ở trang Auth mà ko có route cũ thì về Home
            return isAtAuth ? "/" : null;
          }

          // Lưu route hiện tại để khôi phục sau này (tránh lưu trang Auth)
          if (!isAtAuth) {
            await storage.saveLastRoute(fullLocation).catchError((e) => null);
          }
        }
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

        GoRoute(
          path: "/checkout",
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Map) {
              final details =
                  (extra["details"] as List<CartDetail>?) ?? const [];
              final discountPercent =
                  (extra["discountPercent"] as num?)?.toDouble() ?? 0;
              return OrderPage(
                cartDetails: details,
                discountPercent: discountPercent,
              );
            }
            final details = (extra as List<CartDetail>?) ?? const [];
            return OrderPage(cartDetails: details, discountPercent: 0);
          },
        ),

        GoRoute(path: "/about", builder: (context, state) => const AboutPage()),

        GoRoute(
          path: "/profile",
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    );
  }
}
