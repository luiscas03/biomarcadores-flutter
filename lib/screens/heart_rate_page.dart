import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HeartRatePage extends StatefulWidget {
  const HeartRatePage({super.key});

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  CameraController? _controller;
  bool _processing = false;
  bool _fingerDetected = false;
  
  // Data buffers
  final List<double> _redAvgBuffer = [];
  final List<DateTime> _timeBuffer = [];
  
  // BPM State
  int _bpm = 0;
  double _progress = 0.0;
  bool _done = false;
  
  // Measurement Config
  static const int _windowSize = 30 * 15; // ~15 seconds at 30fps
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use back camera, low resolution for performance
    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      cam,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    
    // Turn on flashlight
    await _controller!.setFlashMode(FlashMode.torch);

    if (!mounted) return;
    setState(() {});

    // Start stream
    _controller!.startImageStream(_processImage);
    _startTime = DateTime.now();
  }

  void _processImage(CameraImage image) {
    if (_processing || _done) return;
    _processing = true;

    // Basic calculation: obtain average red (Y channel in YUV simulates brightness heavily influenced by red when flash is on)
    // Actually in YUV, Y is luma. For blood detection, Y is often "good enough" because blood volume changes affect brightness.
    // Ideally we convert to RGB, but for speed in Dart we use Y plane average.
    
    double avg = 0;
    // Sample center of image for speed
    final int width = image.width;
    final int height = image.height;
    final int total = width * height;
    final int step = 10; // skip pixels for speed
    
    // Safety check
    if (image.planes.isEmpty) {
      _processing = false;
      return;
    }
    
    final yPlane = image.planes[0].bytes;
    int sum = 0;
    int count = 0;
    
    // Only center crop
    final int margin = width ~/ 4;
    
    for (int y = margin; y < height - margin; y += step) {
      for (int x = margin; x < width - margin; x += step) {
        sum += yPlane[y * width + x];
        count++;
      }
    }
    
    if (count > 0) avg = sum / count;

    // Finger Check: Red/Luma should be high due to flash
    bool detected = avg > 30; 
    
    // Smooth state change to avoid flickering UI
    if (mounted) {
       if (detected != _fingerDetected) {
           setState(() => _fingerDetected = detected);
       }
    }

    if (!detected) {
      _processing = false;
      return; 
    }

    // Append to buffer
    final now = DateTime.now();
    
    if (mounted) {
       setState(() {
         _redAvgBuffer.add(avg);
         _timeBuffer.add(now);
         
         // Update progress (aim for 15 seconds)
         final elapsed = now.difference(_startTime!).inMilliseconds;
         _progress = (elapsed / 15000).clamp(0.0, 1.0);
       });
    }

    // Limit buffer size
    if (_redAvgBuffer.length > _windowSize) {
      // Logic would be here to act as ring buffer if we wanted continuous
    }

    if (_progress >= 1.0 && !_done) {
        _calculateBPM();
    }

    _processing = false;
  }

  void _calculateBPM() {
    _done = true;
    _controller?.stopImageStream();
    _controller?.setFlashMode(FlashMode.off);

    // Peak detection algo
    // 1. Smooth signal
    // 2. Find peaks
    // 3. Calc intervals
    
    if (_redAvgBuffer.isEmpty) return;

    // Simple Moving Average Smoothing
    List<double> smoothed = [];
    int window = 5;
    for (int i = 0; i < _redAvgBuffer.length; i++) {
        double wSum = 0;
        int wCount = 0;
        for (int j = i - window; j <= i + window; j++) {
            if (j >= 0 && j < _redAvgBuffer.length) {
                wSum += _redAvgBuffer[j];
                wCount++;
            }
        }
        smoothed.add(wSum / wCount);
    }

    // Find local maxima
    List<int> peaks = [];
    // Need minimum distance between peaks ~0.5 sec (approx 15 frames at 30fps)
    int minDistance = 10; 
    
    for (int i = 1; i < smoothed.length - 1; i++) {
        if (smoothed[i] > smoothed[i-1] && smoothed[i] > smoothed[i+1]) {
           // It's a local max, check context
           if (peaks.isEmpty || (i - peaks.last > minDistance)) {
               peaks.add(i);
           }
        }
    }

    // Calculate BPM
    if (peaks.length < 2) {
        _bpm = 0; // Failed
    } else {
        // Average distance
        double totalDist = 0;
        for (int i = 1; i < peaks.length; i++) {
             // In time
             final t1 = _timeBuffer[peaks[i]];
             final t0 = _timeBuffer[peaks[i-1]];
             totalDist += t1.difference(t0).inMilliseconds;
        }
        double avgMs = totalDist / (peaks.length - 1);
        double bpmVal = 60000 / avgMs;
        
        // Clamp reasonable values
        if (bpmVal < 40 || bpmVal > 200) {
           // Maybe noise
           bpmVal = 0; 
        }
        _bpm = bpmVal.round();
    }
    
    _saveAndExit();
  }

  Future<void> _saveAndExit() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bpm > 0) {
      await prefs.setInt('last_bpm', _bpm);
      await prefs.setString('last_bpm_date', DateTime.now().toIso8601String());
    }

    if (!mounted) return;
    
    // Show verification dialog
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Medición completada"),
        content: Text(_bpm > 0 
           ? "Tu ritmo: $_bpm BPM" 
           : "No pudimos detectar un pulso claro. Intenta de nuevo."),
        actions: [
            TextButton(
                onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(true); // Close page
                },
                child: const Text("OK"),
            )
        ],
      )
    );
  }

  @override
  void dispose() {
    _controller?.setFlashMode(FlashMode.off);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
            children: [
                // Camera Preview (Hidden or dimmed, we don't need to see the finger really)
                Opacity(
                    opacity: 0.5,
                    child: Center(
                        child: CameraPreview(_controller!),
                    )
                ),
                
                // Overlay UI
                SafeArea(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Icon(Icons.favorite, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 20),
                            Text(
                                _fingerDetected ? "Midiendo..." : "Coloca tu dedo", 
                                style: GoogleFonts.poppins(
                                  color: _fingerDetected ? Colors.white : Colors.redAccent, 
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold
                                )
                            ),
                            const SizedBox(height: 10),
                            Text(
                                "Mantén el dedo quieto sobre el flash", 
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)
                            ),
                            const SizedBox(height: 40),
                            
                            // Pulse Graph Visualization
                            Container(
                                height: 100,
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(10)
                                ),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CustomPaint(
                                        painter: SignalPainter(_redAvgBuffer),
                                        size: const Size(double.infinity, 100),
                                    ),
                                ),
                            ),

                            const SizedBox(height: 40),
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: LinearProgressIndicator(value: _progress, color: Colors.redAccent),
                            )
                        ],
                    ),
                ),

                Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                    ),
                )
            ],
        ),
    );
  }
}

class SignalPainter extends CustomPainter {
    final List<double> data;
    SignalPainter(this.data);

    @override
    void paint(Canvas canvas, Size size) {
        if (data.isEmpty) return;
        
        final paint = Paint()
            ..color = Colors.red
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
            
        // Scale data to fit
        // Use last 100 points
        final window = data.length > 100 ? data.sublist(data.length - 100) : data;
        if (window.isEmpty) return;

        double minVal = window.reduce((curr, next) => curr < next ? curr : next);
        double maxVal = window.reduce((curr, next) => curr > next ? curr : next);
        if (maxVal == minVal) maxVal += 1;

        final path = Path();
        final double stepX = size.width / (window.length - 1);
        
        for (int i = 0; i < window.length; i++) {
             final val = window[i];
             final normalized = (val - minVal) / (maxVal - minVal);
             final y = size.height - (normalized * size.height);
             final x = i * stepX;
             
             if (i == 0) path.moveTo(x, y);
             else path.lineTo(x, y);
        }
        
        canvas.drawPath(path, paint);
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
