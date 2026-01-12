import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:biomarcadores/auth/auth_service.dart';
import 'config.dart';

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  final AuthService _authService = AuthService();
  bool _interceptorsConfigured = false;

  Dio get authDio {
    if (!_interceptorsConfigured) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await _authService.getValidAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (DioException error, handler) async {
            if (error.response?.statusCode == 401) {
              final refreshed = await _authService.refreshToken();
              if (refreshed) {
                final token = await _authService.getAccessToken();
                if (token != null) {
                  error.requestOptions.headers['Authorization'] = 'Bearer $token';
                }
                return handler.resolve(await _dio.fetch(error.requestOptions));
              }
              await _authService.logout();
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
            return handler.next(error);
          },
        ),
      );
      _interceptorsConfigured = true;
    }
    return _dio;
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
