import 'dart:async';
import 'dart:io';

import 'package:biomarcadores/api/samples_api.dart';
import 'package:biomarcadores/auth/auth_service.dart';
import 'package:biomarcadores/flex_camera_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  // Sensor & Data State
  StreamSubscription? _accSub, _gyrSub;
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<Activity>? _actSub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  
  int? _localSessionId;
  int? _trackerSessionId;
  bool _syncing = false;
  final _authService = AuthService();
  final _samplesApi = SamplesApi();
  
  AccelerometerEvent? _acc;
  GyroscopeEvent? _gyr;
  int _steps = 0;
  ActivityType? _activityType;

  bool _recording = false;
  Database? _db;
  Timer? _recordingTimer;

  // Measurement State
  int _lastBPM = 0;
  int _lastGlucose = 0;
  int _lastSpO2 = 0; // New SpO2
  String? _lastBPMDate;

  // Chart Data
  final List<FlSpot> _accSpots = [];
  double _timeCounter = 0;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _requestPermissions();
    _listenStreams();
    _observeConnectivity();
    loadBPM();
  }

  Future<void> loadBPM() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastBPM = prefs.getInt('last_bpm') ?? 0;
      _lastGlucose = prefs.getInt('last_glucose') ?? 0;
      _lastSpO2 = prefs.getInt('last_spo2') ?? 0; // Load SpO2
      _lastBPMDate = prefs.getString('last_bpm_date');
    });
  }

  Future<void> _bootstrap() async {
    await _initDb();
    await _loadTrackerSessionId();
    await _syncPendingSamples();
  }

  Future<void> _loadTrackerSessionId() async {
    final remoteId = await _authService.getSessionId();
    if (!mounted) {
      _trackerSessionId = remoteId;
      return;
    }
    setState(() => _trackerSessionId = remoteId);
  }

  Future<void> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'biomarcadores.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at INTEGER NOT NULL,
            note TEXT
          );
        ''');
        // (Same schema as home.dart)
         await db.execute('''
          CREATE TABLE IF NOT EXISTS samples(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ts INTEGER NOT NULL,
            ax REAL, ay REAL, az REAL,
            gx REAL, gy REAL, gz REAL,
            steps INTEGER,
            activity TEXT,
            session_id INTEGER,
            synced INTEGER NOT NULL DEFAULT 0
          );
        ''');
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.insert('sessions', {'started_at': now, 'note': 'default'});
      },
      onUpgrade: (db, oldV, newV) async {
         // (Minimal migration logic for this new screen context, assuming DB exists or is created fresh)
      },
    );

    final cur = await _db!.rawQuery(
      'SELECT id FROM sessions ORDER BY id DESC LIMIT 1',
    );
    _localSessionId = cur.isNotEmpty ? (cur.first['id'] as int) : null;
  }

  Future<void> _requestPermissions() async {
    await [Permission.activityRecognition, Permission.sensors].request();
    var perm = await FlutterActivityRecognition.instance.checkPermission();
    if (perm == ActivityPermission.DENIED ||
        perm == ActivityPermission.PERMANENTLY_DENIED) {
      await FlutterActivityRecognition.instance.requestPermission();
    }
  }

  void _listenStreams() {
    _accSub = accelerometerEvents.listen((e) {
      if (mounted) {
        setState(() {
          _acc = e;
          // Upadte chart data
          _timeCounter += 0.1; // Approximation
          _accSpots.add(FlSpot(_timeCounter, e.x));
          if (_accSpots.length > 50) {
            _accSpots.removeAt(0);
          }
        });
      }
    });

    _gyrSub = gyroscopeEvents.listen((e) => setState(() => _gyr = e));
    _stepSub = Pedometer.stepCountStream.listen(
      (event) => setState(() => _steps = event.steps),
      onError: (e) => debugPrint('Pedometer Error: \$e'),
    );
    _actSub = FlutterActivityRecognition.instance.activityStream
        .handleError((e) => debugPrint('Activity Recognition Error: \$e'))
        .listen((activity) {
          if (mounted) setState(() => _activityType = activity.type);
        });
  }

  void _observeConnectivity() {
    final connectivity = Connectivity();
    _connSub = connectivity.onConnectivityChanged.listen((results) {
      if (_hasNetwork(results)) {
        _syncPendingSamples();
      }
    });
    connectivity.checkConnectivity().then((results) {
      if (_hasNetwork(results)) {
        _syncPendingSamples();
      }
    });
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  void _toggleRecording() {
    setState(() {
      _recording = !_recording;
      if (_recording) {
        _recordingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
          _saveSample();
        });
      } else {
        _recordingTimer?.cancel();
        _recordingTimer = null;
      }
    });
  }

  Future<void> _saveSample() async {
    if (_db == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final sample = {
      'ts': now,
      'ax': _acc?.x ?? 0.0,
      'ay': _acc?.y ?? 0.0,
      'az': _acc?.z ?? 0.0,
      'gx': _gyr?.x ?? 0.0,
      'gy': _gyr?.y ?? 0.0,
      'gz': _gyr?.z ?? 0.0,
      'steps': _steps,
      'activity': _activityType?.name ?? 'UNKNOWN',
      'session_id': _localSessionId,
      'synced': 0,
    };
    await _db!.insert('samples', sample);
    unawaited(_syncPendingSamples());
  }

  Future<void> _syncPendingSamples() async {
    if (_db == null || _trackerSessionId == null || _syncing) return;
    _syncing = true;
    try {
      while (true) {
        final pending = await _db!.query('samples', where: 'synced = 0', orderBy: 'ts', limit: 100);
        if (pending.isEmpty) break;
        final payload = pending.map((row) => {
          'ts': row['ts'], 'ax': row['ax'], 'ay': row['ay'], 'az': row['az'],
          'gx': row['gx'], 'gy': row['gy'], 'gz': row['gz'],
          'steps': row['steps'], 'activity': row['activity'],
        }).toList();

        await _samplesApi.sendSamples(sessionId: _trackerSessionId!, samples: payload);
        final batch = _db!.batch();
        for (final row in pending) {
          batch.update('samples', {'synced': 1}, where: 'id = ?', whereArgs: [row['id']]);
        }
        await batch.commit(noResult: true);
      }
    } catch (e) {
      debugPrint('Sync Error: \$e');
    } finally {
      _syncing = false;
    }
  }

  Future<void> _exportCsv() async {
    if (_db == null) return;
    final rows = await _db!.rawQuery('SELECT * FROM samples ORDER BY ts');
    final buffer = StringBuffer('ts,ax,ay,az,gx,gy,gz,steps,activity,session_id,synced\n');
    for (final r in rows) {
      buffer.writeln([
         r['ts'], r['ax'], r['ay'], r['az'], r['gx'], r['gy'], r['gz'],
         r['steps'], r['activity'], r['session_id'], r['synced']
      ].join(','));
    }
    final dir = await getApplicationDocumentsDirectory();
    final csvPath = p.join(dir.path, 'sensor_dump.csv');
    final file = File(csvPath);
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(csvPath)], text: 'Datos de sensores');
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _gyrSub?.cancel();
    _stepSub?.cancel();
    _actSub?.cancel();
    _connSub?.cancel();
    _recordingTimer?.cancel();
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors based on the image provided (soft gradients, oranges, blues)
    const bgGradient = LinearGradient(
      colors: [Color(0xFFE0F7FA), Color(0xFFFFF3E0), Color(0xFFFBE9E7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    const orangeAccent = Color(0xFFFF7043);
    
    // Values
    final ax = _acc?.x.toStringAsFixed(1) ?? "0.0";
    final ay = _acc?.y.toStringAsFixed(1) ?? "0.0";
    final az = _acc?.z.toStringAsFixed(1) ?? "0.0";
    final activity = _activityType?.name.toUpperCase() ?? "UNKNOWN";


    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Row(
                       children: [
                         const Icon(Icons.monitor_heart_outlined, color: Colors.black87),
                         const SizedBox(width: 8),
                         Text("Biomarcadores", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
                       ],
                     ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.black54),
                      tooltip: 'Cerrar sesión',
                      onPressed: () {
                        _authService.logout().then((_) => Navigator.pushReplacementNamed(context, '/login'));
                      },
                    )
                  ],
                ),
              ),

              // SEARCH BAR (Visual only)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.black38),
                    const SizedBox(width: 10),
                    Text("Buscar", style: GoogleFonts.poppins(color: Colors.black38)),
                  ],
                ),
              ),

              // HERO CARD (BPM Placeholder + Recording Status)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, color: orangeAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(_recording ? "Grabando datos..." : "En reposo", 
                             style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Primary: Glucose
                        Text(_lastGlucose > 0 ? "$_lastGlucose" : "--", style: GoogleFonts.poppins(fontSize: 56, fontWeight: FontWeight.bold, color: orangeAccent)),
                        const SizedBox(width: 8),
                        Text("mg/dL", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, color: orangeAccent)),
                      ],
                    ),
                    // Secondary: BPM
                    if (_lastBPM > 0)
                      Text("Ritmo Cardíaco: $_lastBPM BPM", style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54)),
                    
                    Text(_lastBPMDate != null ? "Última: ${_formatDate(_lastBPMDate!)}" : "Sin mediciones recientes", style: GoogleFonts.poppins(color: Colors.black45, fontSize: 12)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Secondary stats within Hero
                        _buildMiniStat("Pasos", "$_steps", Colors.blue[100]!),
                        _buildMiniStat("SpO2", _lastSpO2 > 0 ? "$_lastSpO2%" : "--", Colors.green[100]!),
                        _buildMiniStat("Actividad", activity, Colors.orange[100]!),
                      ],
                    )
                  ],
                ),
              ),

              // ACCELEROMETER CHART SECTION
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Acelerómetro (X)", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                               Text("X:$ax Y:$ay Z:$az", style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                            ]
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Actions Row (Start/Stop, Flex, Export)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                             ElevatedButton.icon(
                               onPressed: _toggleRecording,
                               style: ElevatedButton.styleFrom(
                                 backgroundColor: _recording ? Colors.redAccent : orangeAccent,
                                 foregroundColor: Colors.white,
                                 shape: const StadiumBorder(),
                               ),
                               icon: Icon(_recording ? Icons.stop : Icons.play_arrow),
                               label: Text(_recording ? "Detener" : "Grabar"),
                             ),
                             const SizedBox(width: 10),
                             OutlinedButton.icon(
                               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FlexCameraPage())),
                               style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                               icon: const Icon(Icons.camera_alt_outlined),
                               label: const Text("Fleximetría"),
                             ),
                             const SizedBox(width: 10),
                             IconButton.filledTonal(
                               icon: const Icon(Icons.ios_share),
                               onPressed: _exportCsv,
                             )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // CHART
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _accSpots.isEmpty ? [const FlSpot(0, 0)] : _accSpots,
                                isCurved: true,
                                color: orangeAccent,
                                barWidth: 3,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: orangeAccent.withOpacity(0.1),
                                ),
                              ),
                            ],
                            minY: -15, // Approximate range for accelerometer
                            maxY: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  
  String _formatDate(String iso) {
     final dt = DateTime.parse(iso);
     return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
  
}
