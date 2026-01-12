import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:biomarcadores/api/api_client.dart';
import 'package:biomarcadores/auth/auth_service.dart';
import 'package:biomarcadores/screens/home_wrapper.dart';
import 'package:biomarcadores/biomarcadores/login/login_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BiomarcadoresApp());
}

class BiomarcadoresApp extends StatelessWidget {
  const BiomarcadoresApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biomarcadores',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // <--- importante para interceptor
      theme: ThemeData(useMaterial3: true),
      routes: {
        '/': (_) => const _Gate(),      // decide si va a home o login
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomeWrapper(), // tu pantalla principal
      },
      initialRoute: '/',
    );
  }
}

// Pantalla que decide
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
    final has = await _auth.getValidAccessToken();
    if (!mounted) return;
    if (has != null) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
