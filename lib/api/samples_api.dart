import 'package:dio/dio.dart';

import 'package:biomarcadores/api/api_client.dart';

class SamplesApi {
  SamplesApi({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<void> sendSamples({
    required int sessionId,
    required List<Map<String, dynamic>> samples,
  }) async {
    final Dio dio = _apiService.authDio;
    await dio.post(
      '/api/tracker/samples/batch/',
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
      data: {
        'session_id': sessionId,
        'samples': samples,
      },
    );
  }
}
