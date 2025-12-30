import 'package:b2205946_duonghuuluan_luanvan/features/auth/view/login_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/view/register_page.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/viewmodels/auth_viewmodel.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: null,
    redirect: (context, state) {
      final authVM = context.read<AuthViewmodel>();
      final bool loggedIn = authVM.isAuthenticated; // Kiểm tra đã login chưa
      final bool loggingIn = state.matchedLocation == '/login';
      final bool registering = state.matchedLocation == '/register';

      // 1. Nếu chưa đăng nhập và không phải đang ở trang login/register -> đá về login
      if (!loggedIn && !loggingIn && !registering) return '/login';

      // 2. Nếu đã đăng nhập mà vẫn ở trang login -> đá vào trang chủ (Home)
      if (loggedIn && (loggingIn || registering)) return '/';

      return null;
    },
    routes: [
      GoRoute(path: "/login", builder: (context, state) => const LoginPage()),

      GoRoute(
        path: "/register",
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: "/",
        builder: (context, state) => const Scaffold(
          body: Center(child: Text("HomePage - Đã đăng nhập")),
        ),
      ),
    ],
  );
}
