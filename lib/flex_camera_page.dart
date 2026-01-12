import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'flex_measure_page.dart';

class FlexCameraPage extends StatefulWidget {
  const FlexCameraPage({super.key});
  @override
  State<FlexCameraPage> createState() => _FlexCameraPageState();
}

class _FlexCameraPageState extends State<FlexCameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  FlashMode _flashMode = FlashMode.auto;
  bool _busy = false;
  bool _initializing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error =
              'Se requiere permiso de cámara para la fleximetría. Reintenta y concédelo.';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No se encontró ninguna cámara disponible.');
        return;
      }
      _cameras = cameras;

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo iniciar la cámara: $e');
      }
    } finally {
      if (mounted) setState(() => _initializing = false);
    }
  }

  Future<void> _setFlash(FlashMode mode) async {
    if (_controller == null) return;
    await _controller!.setFlashMode(mode);
    setState(() => _flashMode = mode);
  }

  Future<void> _takePhoto() async {
    if (_controller == null || _busy || _initializing) return;
    setState(() => _busy = true);
    try {
      final shot = await _controller!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final outPath = p.join(
        dir.path,
        'fleximetria_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(shot.path).copy(outPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto guardada: $outPath')),
      );

      final angle = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FlexMeasurePage(imagePath: outPath),
        ),
      );
      if (mounted && angle is double) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ángulo medido: ${angle.toStringAsFixed(1)}°')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo tomar la foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Fleximetría - Cámara')),
      body: Builder(
        builder: (_) {
          if (_error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _init,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_initializing || ctrl == null || !ctrl.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              Positioned.fill(child: CameraPreview(ctrl)),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PopupMenuButton<FlashMode>(
                      initialValue: _flashMode,
                      onSelected: _setFlash,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: FlashMode.off, child: Text('Flash: Off')),
                        PopupMenuItem(
                            value: FlashMode.auto, child: Text('Flash: Auto')),
                        PopupMenuItem(
                            value: FlashMode.always, child: Text('Flash: On')),
                        PopupMenuItem(
                            value: FlashMode.torch, child: Text('Linterna')),
                      ],
                      child: const Icon(
                        Icons.flash_on,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    FloatingActionButton.large(
                      onPressed: _busy ? null : _takePhoto,
                      child: _busy
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                  strokeWidth: 3, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
