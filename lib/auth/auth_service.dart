import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biomarcadores/api/config.dart';
import 'package:biomarcadores/api/manychat_api.dart';
class AuthService {
  AuthService() : _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  final Dio _dio;

  static const _kAccess = 'jwt_access';
  static const _kRefresh = 'jwt_refresh';
  static const _kPhone = 'phone_e164';
  static const _kSession = 'tracker_session_id';
  static const _kManychatProfile = 'manychat_profile';


  Future<String?> getAccessToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kAccess);
  }

  Future<String?> getValidAccessToken({
    Duration tolerance = const Duration(minutes: 1),
  }) async {
    var token = await getAccessToken();
    if (token == null) {
      final refreshed = await refreshToken();
      if (!refreshed) return null;
      return getAccessToken();
    }
    if (_tokenNeedsRefresh(token, tolerance)) {
      final refreshed = await refreshToken();
      if (!refreshed) return null;
      token = await getAccessToken();
    }
    return token;
  }

  Future<int?> getSessionId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kSession);
  }

  Future<void> _saveSessionId(int id) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSession, id);
  }

  Future<String?> getRefreshToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRefresh);
  }

  Future<String?> getSavedPhone() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kPhone);    
  }

  Future<void> saveTokens({
    required String access,
    String? refresh,
    String? phone,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, access);
    if (refresh != null) await p.setString(_kRefresh, refresh);
    if (phone != null) await p.setString(_kPhone, phone);
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kSession);
    await p.remove(_kManychatProfile);
  }

  Future<bool> refreshToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    try {
      final res = await _dio.post(
        '/api/auth/refresh/',
        data: {'refresh': refresh},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = res.data as Map<String, dynamic>;
      final access = data['access'] as String;
      await saveTokens(access: access);
      return true;
    } catch (_) {
      return false;
    }
  }

  // login contra tu backend usando firebase
  Future<void> exchangeFirebaseIdToken(
    String idToken, {
    String? phoneE164,
  }) async {
    final res = await _dio.post(
      '/api/tracker/auth/firebase-login/',
      data: {'id_token': idToken},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final data = res.data as Map<String, dynamic>;
    final access = data['access'] as String;
    final refresh = data['refresh'] as String?;
    final backendPhone = data['phone'] as String?;
    await saveTokens(access: access, refresh: refresh, phone: phoneE164 ?? backendPhone);

    // crea la sesion en Django
    final sessionId = await createTrackerSession(note: 'sesion desde app');
    await _saveSessionId(sessionId);

    // consulta ManyChat en background y lo cachea
    await _fetchAndCacheManychatProfile(phoneE164 ?? backendPhone);
  }

  // crea la sesion en /api/tracker/sessions/
  Future<int> createTrackerSession({String note = 'sesion desde app'}) async {
    final token = await getValidAccessToken();
    if (token == null) {
      throw Exception('No hay JWT para crear la sesion');
    }

    final res = await _dio.post(
      '/api/tracker/sessions/',
      data: {'note': note},
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
    );
    print("El token es: "+token);
    print(_kAccess);
    print(_kRefresh);
    return res.data['id'] as int;
  }

  Future<void> _fetchAndCacheManychatProfile(String? phone) async {
    if (phone == null) return;
    try {
      final api = ManychatApi();
      final data = await api.lookup(phone);
      if (data == null) return;
      final p = await SharedPreferences.getInstance();
      await p.setString(_kManychatProfile, jsonEncode(data));
    } catch (_) {
      // silencioso: no bloquea login
    }
  }

  Future<Map<String, dynamic>?> getCachedManychatProfile() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kManychatProfile);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool _tokenNeedsRefresh(String token, Duration tolerance) {
    try {
      final remaining = JwtDecoder.getRemainingTime(token);
      return remaining <= tolerance;
    } catch (_) {
      return true;
    }
  }
}
