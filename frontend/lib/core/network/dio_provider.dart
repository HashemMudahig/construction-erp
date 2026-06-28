import "package:dio/dio.dart";

import "../config/app_config.dart";

/// Dio provider. The backend uses the standard envelope
/// `{ success, message, data }`. Parse it in repositories.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: appConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {"Content-Type": "application/json"},
  ));
  return dio;
});