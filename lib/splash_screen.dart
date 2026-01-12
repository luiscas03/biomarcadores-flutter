import 'package:flutter/material.dart';
import 'package:biomarcadores/services/permission_service.dart';
import 'package:biomarcadores/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PermissionService _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    _handlePermissionsAndNavigate();
  }

  Future<void> _handlePermissionsAndNavigate() async {
    // Espera un poco para que la splash screen sea visible.
    await Future.delayed(const Duration(seconds: 1));

    await _permissionService.requestCorePermissions();

    // Navega a la pantalla principal sin importar el resultado,
    // la app puede funcionar con funcionalidades limitadas.
    // Las comprobaciones específicas se harán en cada pantalla que use un permiso.
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}