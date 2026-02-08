import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    final authVM = context.read<AuthViewmodel>();
    _router = AppRouter.createRouter(authVM);
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (_) {}

    _deepLinkSub = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    final bool isPaymentResult =
        uri.host == "payment-result" ||
        uri.path == "/payment-result" ||
        uri.path == "/order-result";
    if (!isPaymentResult) return;

    final orderId = int.tryParse(uri.queryParameters["orderId"] ?? "") ?? 0;
    if (orderId <= 0) return;

    _router.go(
      "/order-result",
      extra: {
        "orderId": orderId,
        "paymentUrl": "",
        "status": uri.queryParameters["status"] ?? "",
      },
    );
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Helmet App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
