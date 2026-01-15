import 'package:dio/dio.dart';

import 'package:biomarcadores/api/api_client.dart';

class PpgApi {
  PpgApi({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<Map<String, dynamic>> measure({
    required List<double> r,
    required List<double> g,
    required List<double> b,
    double? fps,
    List<double>? timestamps,
  }) async {
    final Dio dio = _apiService.authDio;
    final payload = <String, dynamic>{
      'r': r,
      'g': g,
      'b': b,
    };
    if (fps != null && fps > 0) {
      payload['fps'] = fps;
    }
    if (timestamps != null && timestamps.isNotEmpty) {
      payload['timestamps'] = timestamps;
    }

    final res = await dio.post(
      '/api/v1/ppg/measure/',
      options: Options(headers: {'Content-Type': 'application/json'}),
      data: payload,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
