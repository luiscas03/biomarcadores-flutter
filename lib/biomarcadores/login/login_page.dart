import 'package:dio/dio.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:biomarcadores/auth/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _fb = FirebaseAuth.instance;
  
  final _phoneCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _verificationId;
  bool _sending = false;
  bool _verifying = false;
  String _lastPhoneE164 = '';
  bool _isPhoneValid = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneCtl.dispose();
    _codeCtl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendOtpWithFirebase() async {
    if (!_isPhoneValid) {
      _showSnackBar('Por favor ingresa un número válido', isError: true);
      return;
    }

    final phoneE164 = _lastPhoneE164.isNotEmpty ? _lastPhoneE164 : _phoneCtl.text.trim();

    setState(() => _sending = true);
    try {
      await _fb.verifyPhoneNumber(
        phoneNumber: phoneE164,
        verificationCompleted: (PhoneAuthCredential cred) async {
          await _fb.signInWithCredential(cred);
          await _afterFirebaseLogin(phoneE164);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar('Error: ${e.message ?? "Verificación fallida"}', isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          _showSnackBar('✓ Código enviado por SMS', isError: false);
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
    if (smsCode.isEmpty || smsCode.length < 6) {
      _showSnackBar('Ingresa el código de 6 dígitos', isError: true);
      return;
    }
    if (_verificationId == null) {
      _showSnackBar('Primero envía el código', isError: true);
      return;
    }

    setState(() => _verifying = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _fb.signInWithCredential(cred);
      await _afterFirebaseLogin(_lastPhoneE164);
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Código incorrecto: ${e.message}', isError: true);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _afterFirebaseLogin(String? phoneE164) async {
    final user = _fb.currentUser;
    if (user == null) {
      _showSnackBar('Error de autenticación', isError: true);
      return;
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      _showSnackBar('No se pudo obtener token', isError: true);
      return;
    }

    try {
      await _auth.exchangeFirebaseIdToken(idToken, phoneE164: phoneE164);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    } on DioException catch (e) {
      final serverMsg = e.response?.data?.toString() ?? e.message ?? 'Error desconocido';
      if (mounted) {
        _showSnackBar('Login falló: $serverMsg', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error inesperado: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF7043);
    const bgGradient = LinearGradient(
      colors: [Color(0xFFFFF3E0), Color(0xFFFBE9E7), Color(0xFFE0F7FA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.monitor_heart_outlined,
                          size: 50,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        'Biomarcadores',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitoreo de salud inteligente',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Card Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Iniciar Sesión',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Phone Field
                            IntlPhoneField(
                              decoration: InputDecoration(
                                labelText: 'Número de teléfono',
                                labelStyle: GoogleFonts.poppins(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: const Icon(Icons.phone, color: primaryColor),
                              ),
                              initialCountryCode: 'CO',
                              onChanged: (phone) {
                                setState(() {
                                  _lastPhoneE164 = phone.completeNumber;
                                  _isPhoneValid = phone.isValidNumber();
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Send Code Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _sending ? null : _sendOtpWithFirebase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  disabledBackgroundColor: Colors.grey[300],
                                ),
                                icon: _sending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.sms_outlined),
                                label: Text(
                                  _sending ? 'Enviando...' : 'Enviar código',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            if (_verificationId != null) ...[
                              const SizedBox(height: 32),
                              const Divider(),
                              const SizedBox(height: 24),

                              // Code Field
                              TextField(
                                controller: _codeCtl,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: 'Código de verificación',
                                  labelStyle: GoogleFonts.poppins(),
                                  hintText: '000000',
                                  hintStyle: GoogleFonts.poppins(letterSpacing: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: primaryColor, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                                  counterText: '',
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Verify Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: FilledButton.icon(
                                  onPressed: _verifying ? null : _confirmCode,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: _verifying
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.check_circle_outline),
                                  label: Text(
                                    _verifying ? 'Verificando...' : 'Verificar y entrar',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Footer
                      Text(
                        'Al continuar, aceptas nuestros términos y condiciones',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
