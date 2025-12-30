import 'package:b2205946_duonghuuluan_luanvan/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.read<AuthViewmodel>();

    final router = AppRouter.createRouter(authVM);
    return MaterialApp.router(
      title: 'Helmet App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
