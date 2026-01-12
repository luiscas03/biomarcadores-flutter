import 'package:flutter/material.dart';
import 'package:biomarcadores/api/api_client.dart';       // define navigatorKey
import 'package:biomarcadores/auth/auth_service.dart';
import 'package:biomarcadores/biomarcadores/login/login_page.dart';
import 'package:biomarcadores/biomarcadores/home/home.dart';

class BiomarcadoresApp extends StatelessWidget {
  const BiomarcadoresApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biomarcadores',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // <- importante para el interceptor de Dio
      theme: ThemeData(useMaterial3: true),
      routes: {
        '/':      (_) => const _Gate(),
        '/login': (_) => const LoginPage(),
        '/home':  (_) => const SensorHome(),
      },
      initialRoute: '/',
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate({super.key});
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final token = await _auth.getValidAccessToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
