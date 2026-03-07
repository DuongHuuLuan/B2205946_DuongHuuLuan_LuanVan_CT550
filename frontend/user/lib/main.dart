import 'package:b2205946_duonghuuluan_luanvan/app/app.dart';
import 'package:b2205946_duonghuuluan_luanvan/app/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/notifications/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await PushNotificationService.instance.bootstrap();
  runApp(MultiProvider(providers: Providers, child: const MyApp()));
}
