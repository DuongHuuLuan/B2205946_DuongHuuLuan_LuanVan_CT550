import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/notifications/push_notification_service.dart';
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
  late final AuthViewmodel _authVM;
  final PushNotificationService _pushService = PushNotificationService.instance;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _authVM = context.read<AuthViewmodel>();
    _router = AppRouter.createRouter(_authVM);
    _pushService.attachRouter(_router);
    _authVM.addListener(_handleAuthStateChanged);
    unawaited(_syncPushState());
    _initDeepLinks();
  }

  void _handleAuthStateChanged() {
    unawaited(_syncPushState());
  }

  Future<void> _syncPushState() async {
    if (!_authVM.isInitialized) {
      _pushService.setNavigationReady(false);
      return;
    }

    final isAuthenticated = _authVM.isAuthenticated;
    _pushService.setNavigationReady(isAuthenticated);
    if (isAuthenticated) {
      await _pushService.syncDeviceRegistration();
    }
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
        "valid": uri.queryParameters["valid"] ?? "",
      },
    );
  }

  @override
  void dispose() {
    _authVM.removeListener(_handleAuthStateChanged);
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
