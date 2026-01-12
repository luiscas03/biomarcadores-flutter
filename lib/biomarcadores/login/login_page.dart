import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:biomarcadores/auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _fb = FirebaseAuth.instance;
  

  final _phoneCtl = TextEditingController();
  final _codeCtl = TextEditingController();

  String? _verificationId;
  bool _sending = false;
  bool _verifying = false;
  String _lastPhoneE164 = ''; // guardamos el +57...

  @override
  void dispose() {
    _phoneCtl.dispose();
    _codeCtl.dispose();
    super.dispose();
  }

  Future<void> _sendOtpWithFirebase() async {
    final phoneE164 =
        _lastPhoneE164.isNotEmpty ? _lastPhoneE164 : _phoneCtl.text.trim();

    if (phoneE164.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa un número')));
      return;
    }

    setState(() => _sending = true);
    try {
      await _fb.verifyPhoneNumber(
        phoneNumber: phoneE164,
        verificationCompleted: (PhoneAuthCredential cred) async {
          // Android puede hacer auto-verificación
          await _fb.signInWithCredential(cred);
          await _afterFirebaseLogin(phoneE164);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fallo verificación: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código enviado por SMS')),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmCode() async {
    final smsCode = _codeCtl.text.trim();
    if (smsCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa el código')));
      return;
    }
    if (_verificationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Primero envía el código')));
      return;
    }

    setState(() => _verifying = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _fb.signInWithCredential(cred);

      // ahora intercambiamos con tu backend
      await _afterFirebaseLogin(_lastPhoneE164);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error Firebase: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  /// 🚩 Aquí es donde metemos TU AuthService.exchangeFirebaseIdToken(...)

  Future<void> _afterFirebaseLogin(String? phoneE164) async {
    final user = _fb.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase no tiene usuario autenticado')),
      );
      return;
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener id_token de Firebase'),
        ),
      );
      return;
    }

    // 🔎 DEBUG: ver tamaño y comienzo del token
    debugPrint('🔥 ID TOKEN LEN: ${idToken.length}');
    debugPrint('🔥 ID TOKEN START: ${idToken.substring(0, 80)}');

    try {
      await _auth.exchangeFirebaseIdToken(idToken, phoneE164: phoneE164);

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    } on DioException catch (e) {
      // 👇 aquí es donde antes se caía
      final serverMsg =
          e.response?.data?.toString() ?? e.message ?? 'Error desconocido';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login backend falló: $serverMsg')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login biomarcadores')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            IntlPhoneField(
              decoration: const InputDecoration(
                labelText: 'Número',
                border: OutlineInputBorder(),
              ),
              initialCountryCode: 'CO',
              onChanged: (phone) {
                _lastPhoneE164 = phone.completeNumber;
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _sendOtpWithFirebase,
                icon: const Icon(Icons.sms),
                label: Text(_sending ? 'Enviando...' : 'Enviar código'),
              ),
            ),
            const Divider(height: 32),
            TextField(
              controller: _codeCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código recibido',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _verifying ? null : _confirmCode,
                child: Text(
                  _verifying ? 'Verificando...' : 'Verificar y entrar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
