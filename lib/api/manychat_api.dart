import 'package:dio/dio.dart';

import 'package:biomarcadores/api/api_client.dart';

class ManychatApi {
  ManychatApi({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  /// Consulta ManyChat por teléfono E.164 (+57...).
  /// Devuelve el JSON como Map o null si no hay dato.
  Future<Map<String, dynamic>?> lookup(String phone) async {
    final dio = _apiService.authDio;
    final res = await dio.post(
      '/api/tracker/manychat/lookup/',
      data: {'phone': phone},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    if (res.statusCode == 200) return res.data as Map<String, dynamic>;
    return null;
  }
}
