import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Dio instance provider.
///
/// The backend uses the standard envelope `{ success, message, data }`.
/// The response interceptor unwraps `data` on success and throws `ApiException`
/// on `success=false`. The request interceptor injects the JWT bearer token
/// from `shared_preferences`.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: appConfig.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_AuthInterceptor());
  dio.interceptors.add(_EnvelopeInterceptor());

  return dio;
});

/// Thrown when the backend returns `success=false`.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.errors = const [],
    this.statusCode = 0,
  });

  final String message;
  final List<ApiError> errors;
  final int statusCode;

  ApiError? firstError() => errors.isEmpty ? null : errors.first;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// A single error item from the backend error envelope.
class ApiError {
  ApiError({required this.code, this.field, required this.detail});

  final String code;
  final String? field;
  final String detail;

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: json['code'] as String? ?? 'UNKNOWN',
        field: json['field'] as String?,
        detail: json['detail'] as String? ?? '',
      );
}

/// Token storage keys.
const _kTokenKey = 'erp_token';
const _kEmailKey = 'erp_email';

Future<String?> readToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kTokenKey);
}

Future<void> writeToken(String token, String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kTokenKey, token);
  await prefs.setString(_kEmailKey, email);
}

Future<void> clearToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kTokenKey);
  await prefs.remove(_kEmailKey);
}

/// Injects `Authorization: Bearer <token>` on every request.
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Read token synchronously from cache if available; fall back to async read.
    // Dio interceptors can be async.
    readToken().then((token) {
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }).catchError((_) {
      handler.next(options);
      return null;
    });
  }
}

/// Unwraps the standard envelope `{ success, message, data }`.
class _EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('success')) {
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';
      if (!success) {
        final errorsRaw = data['errors'] as List? ?? [];
        final errors = errorsRaw
            .map((e) => ApiError.fromJson(e as Map<String, dynamic>))
            .toList();
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: ApiException(
              message: message,
              errors: errors,
              statusCode: response.statusCode ?? 0,
            ),
          ),
        );
        return;
      }
      // Unwrap data
      response.data = data['data'];
      handler.next(response);
    } else {
      handler.next(response);
    }
  }
}