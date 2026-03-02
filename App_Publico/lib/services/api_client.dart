import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente HTTP padrão do app público.
///
/// - Base URL: Back-end (Spring)
/// - Injeta Authorization Bearer automaticamente usando o token do Supabase
/// - Faz refresh do token quando expira
class ApiClient {
  static final ApiClient _singleton = ApiClient._internal();

  factory ApiClient() => _singleton;

  late final Dio dio;
  final SupabaseClient _supabase = Supabase.instance.client;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.kyarem.nkwflow.com/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final session = _supabase.auth.currentSession;
            final token = session?.accessToken;

            if (token != null) {
              if (kDebugMode) {
                debugPrint('Supabase JWT (antes do refresh): $token');
              }

              if (session!.isExpired) {
                final refreshed = await _supabase.auth.refreshSession();
                final newToken = refreshed.session?.accessToken;

                if (kDebugMode) {
                  debugPrint('Supabase JWT (depois do refresh): ${newToken ?? 'null'}');
                }

                if (newToken != null) {
                  options.headers['Authorization'] = 'Bearer $newToken';
                }
              } else {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } else {
              if (kDebugMode) {
                debugPrint('Supabase JWT: sessão nula ou sem token, request sem Authorization.');
              }
            }
          } catch (e) {
            debugPrint('ApiClient interceptor error: $e');
          }
          return handler.next(options);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: false,
          requestHeader: false,
          responseHeader: false,
          error: true,
        ),
      );
    }
  }
}
