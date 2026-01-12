import 'package:biomarcadores/screens/heart_rate_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MeasureScreen extends StatelessWidget {
  const MeasureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const coralColor = Color(0xFFFF7043);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo claro
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: coralColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Medir con cámara",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // ILUSTRACIÓN (Mockup)
                    _buildPhoneIllustration(),
                    
                    const SizedBox(height: 40),

                    // INSTRUCCIONES
                    _buildInstructionStep(
                      icon: Icons.touch_app,
                      text: "1. Coloca suavemente tu dedo sobre la cámara y el flash.",
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionStep(
                      icon: Icons.vibration, // Icono representativo de "quieto"
                      text: "2. Mantén el teléfono quieto.",
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionStep(
                      icon: Icons.timer_outlined,
                      text: "3. Espera unos segundos mientras medimos.",
                    ),

                    const SizedBox(height: 40),

                    // BOTÓN PRINCIPAL
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navegar a Medición Real
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HeartRatePage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: coralColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: coralColor.withOpacity(0.4),
                        ),
                        child: Text(
                          "Iniciar medición",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // PRIVACIDAD
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, size: 18, color: Colors.blueGrey[400]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Usamos la cámara solo durante la medición. No guardamos imágenes, solo tus datos.",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.blueGrey[400],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                     // BARRA DE PROGRESO (Visual)
                    Container(
                      height: 6,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                     const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: const Color(0xFFFF7043)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneIllustration() {
    return Container(
      width: 160,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[200]!, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cámara y Flash simulados
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cámara
                  Container(
                     width: 40,
                     height: 40,
                     decoration: BoxDecoration(
                       color: Colors.black12,
                       shape: BoxShape.circle,
                       border: Border.all(color: Colors.grey[300]!),
                     ),
                     child: const Icon(Icons.camera_alt, color: Colors.black26, size: 20),
                  ),
                  const SizedBox(width: 12),
                   // Flash (con resplandor)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                     child: const Icon(Icons.flash_on, color: Colors.orange, size: 18),
                  ),
                ],
              ),
            ),
          ),
          
          // Dedo simulado (semi-transparente sobre la cámara)
          Positioned(
            top: 30,
            right: 30,
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCCBC).withOpacity(0.9), // Tono piel
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
