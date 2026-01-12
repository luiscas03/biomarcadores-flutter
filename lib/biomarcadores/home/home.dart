import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:biomarcadores/flex_camera_page.dart';
import 'package:biomarcadores/auth/auth_service.dart';
import 'package:biomarcadores/api/samples_api.dart';

class SensorHome extends StatefulWidget {
  const SensorHome({super.key});
  @override
  State<SensorHome> createState() => _SensorHomeState();
}

class _SensorHomeState extends State<SensorHome> {
  // Subscriptions to sensor streams
  StreamSubscription? _accSub, _gyrSub;
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<Activity>? _actSub;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  int? _localSessionId;
  int? _trackerSessionId;
  bool _syncing = false;
  final _authService = AuthService();
  final _samplesApi = SamplesApi();
  // Last known sensor values
  AccelerometerEvent? _acc;
  GyroscopeEvent? _gyr;
  int _steps = 0;
  ActivityType? _activityType;

  bool _recording = false;
  Database? _db;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _requestPermissions();
    _listenStreams();
    _observeConnectivity();
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
        if (oldV < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sessions(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              started_at INTEGER NOT NULL,
              note TEXT
            );
          ''');
          await db.execute(
            'ALTER TABLE samples ADD COLUMN session_id INTEGER;',
          );
          final now = DateTime.now().millisecondsSinceEpoch;
          final sid = await db.insert('sessions', {
            'started_at': now,
            'note': 'migrated',
          });
          await db.update('samples', {'session_id': sid});
        }
        if (oldV < 3) {
          await db.execute(
            'ALTER TABLE samples ADD COLUMN synced INTEGER NOT NULL DEFAULT 0;',
          );
        }
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
    _accSub = accelerometerEvents.listen((e) => setState(() => _acc = e));
    _gyrSub = gyroscopeEvents.listen((e) => setState(() => _gyr = e));

    _stepSub = Pedometer.stepCountStream.listen(
      (event) => setState(() => _steps = event.steps),
      onError: (e) => debugPrint('Pedometer Error: $e'),
    );

    _actSub = FlutterActivityRecognition.instance.activityStream
        .handleError((e) => debugPrint('Activity Recognition Error: $e'))
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
        _recordingTimer = Timer.periodic(const Duration(milliseconds: 50), (
          timer,
        ) {
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

    // 1) armo el sample UNA sola vez, sin nulos
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

    // 2) guardo local
    await _db!.insert('samples', sample);

    // 3) intento sincronizar pendientes en background
    unawaited(_syncPendingSamples());
  }

  Future<void> _syncPendingSamples() async {
    if (_db == null) return;
    if (_trackerSessionId == null) return;
    if (_syncing) return;
    _syncing = true;
    try {
      while (true) {
        final pending = await _db!.query(
          'samples',
          where: 'synced = 0',
          orderBy: 'ts',
          limit: 100,
        );
        if (pending.isEmpty) break;
        final payload = pending
            .map(
              (row) => {
                'ts': row['ts'],
                'ax': row['ax'],
                'ay': row['ay'],
                'az': row['az'],
                'gx': row['gx'],
                'gy': row['gy'],
                'gz': row['gz'],
                'steps': row['steps'],
                'activity': row['activity'],
              },
            )
            .toList();

        await _samplesApi.sendSamples(
          sessionId: _trackerSessionId!,
          samples: payload,
        );

        final batch = _db!.batch();
        for (final row in pending) {
          batch.update(
            'samples',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
        await batch.commit(noResult: true);
      }
    } catch (e) {
      debugPrint('No se pudo sincronizar samples pendientes: $e');
    } finally {
      _syncing = false;
    }
  }

  Future<void> _exportCsv() async {
    if (_db == null) return;
    final rows = await _db!.rawQuery('SELECT * FROM samples ORDER BY ts');
    final buffer = StringBuffer('ts,ax,ay,az,gx,gy,gz,steps,activity,session_id,synced\n');
    for (final r in rows) {
      buffer.writeln(
        [
          r['ts'],
          r['ax'],
          r['ay'],
          r['az'],
          r['gx'],
          r['gy'],
          r['gz'],
          r['steps'],
          r['activity'],
          r['session_id'],
          r['synced'],
        ].join(','),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final csvPath = p.join(dir.path, 'sensor_dump.csv');
    final file = File(csvPath);
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(csvPath)], text: 'Datos de sensores');
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
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
    final acc = _acc;
    final gyr = _gyr;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biomarcadores'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Tile(
            title: 'Acelerómetro (m/s²)',
            lines:
                acc == null
                    ? ['x: –', 'y: –', 'z: –']
                    : [
                      'x: ${acc.x.toStringAsFixed(2)}',
                      'y: ${acc.y.toStringAsFixed(2)}',
                      'z: ${acc.z.toStringAsFixed(2)}',
                    ],
          ),
          _Tile(
            title: 'Giroscopio (rad/s)',
            lines:
                gyr == null
                    ? ['x: –', 'y: –', 'z: –']
                    : [
                      'x: ${gyr.x.toStringAsFixed(2)}',
                      'y: ${gyr.y.toStringAsFixed(2)}',
                      'z: ${gyr.z.toStringAsFixed(2)}',
                    ],
          ),
          _Tile(
            title: 'Pasos / Actividad',
            lines: [
              'Pasos: $_steps',
              'Actividad: ${_activityType?.name ?? '—'}',
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _toggleRecording,
            child: Text(_recording ? 'Detener registro' : 'Iniciar registro'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FlexCameraPage()));
            },
            icon: const Icon(Icons.straighten),
            label: const Text('Fleximetría (cámara + flash)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _exportCsv,
            icon: const Icon(Icons.ios_share),
            label: const Text('Exportar CSV'),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _Tile({required this.title, required this.lines});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final l in lines) Text(l),
          ],
        ),
      ),
    );
  }
}
