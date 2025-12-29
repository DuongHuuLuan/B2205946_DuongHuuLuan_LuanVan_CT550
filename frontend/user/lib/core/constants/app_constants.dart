import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static final baseUrl = dotenv.env["BASE_URL"] ?? "http://10.0.2.2:8000";

  static final Duration connectTimeout = Duration(
    seconds: int.parse(dotenv.env['CONNECT_TIMEOUT'] ?? '10'),
  );

  static final Duration receiveTimeout = Duration(
    seconds: int.parse(dotenv.env['RECEIVE_TIMEOUT'] ?? '15'),
  );
}
