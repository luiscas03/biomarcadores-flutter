import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Measurement {
  Measurement({
    this.id,
    required this.ts,
    required this.bpm,
    required this.spo2,
    required this.glucose,
    this.confidence,
    this.snrDb,
    this.motionPct,
    this.qualityValid = false,
    this.signal,
    this.timestamps,
    this.synced = 0,
  });

  final int? id;
  final DateTime ts;
  final int bpm;
  final int spo2;
  final int glucose;
  final double? confidence;
  final double? snrDb;
  final double? motionPct;
  final bool qualityValid;
  final List<double>? signal;
  final List<double>? timestamps;
  final int synced;

  Map<String, dynamic> toMap() {
    return {
      'ts': ts.millisecondsSinceEpoch,
      'bpm': bpm,
      'spo2': spo2,
      'glucose': glucose,
      'confidence': confidence,
      'snr_db': snrDb,
      'motion_pct': motionPct,
      'quality_valid': qualityValid ? 1 : 0,
      'signal_json': signal == null ? null : jsonEncode(signal),
      'timestamps_json': timestamps == null ? null : jsonEncode(timestamps),
      'synced': synced,
    };
  }

  static Measurement fromMap(Map<String, dynamic> map) {
    List<double>? parseList(String key) {
      final raw = map[key];
      if (raw == null) return null;
      try {
        final list = jsonDecode(raw as String) as List;
        return list.map((e) => (e as num).toDouble()).toList();
      } catch (_) {
        return null;
      }
    }

    return Measurement(
      id: map['id'] as int?,
      ts: DateTime.fromMillisecondsSinceEpoch(map['ts'] as int),
      bpm: (map['bpm'] as num?)?.toInt() ?? 0,
      spo2: (map['spo2'] as num?)?.toInt() ?? 0,
      glucose: (map['glucose'] as num?)?.toInt() ?? 0,
      confidence: (map['confidence'] as num?)?.toDouble(),
      snrDb: (map['snr_db'] as num?)?.toDouble(),
      motionPct: (map['motion_pct'] as num?)?.toDouble(),
      qualityValid: (map['quality_valid'] as num?)?.toInt() == 1,
      signal: parseList('signal_json'),
      timestamps: parseList('timestamps_json'),
      synced: (map['synced'] as num?)?.toInt() ?? 0,
    );
  }
}

class MeasurementStore {
  static Database? _db;

  static Future<Database> _openDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'biomarcadores.db');
    final db = await openDatabase(path);
    await db.execute('''
      CREATE TABLE IF NOT EXISTS measurements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts INTEGER NOT NULL,
        bpm INTEGER,
        spo2 INTEGER,
        glucose INTEGER,
        confidence REAL,
        snr_db REAL,
        motion_pct REAL,
        quality_valid INTEGER,
        signal_json TEXT,
        timestamps_json TEXT,
        synced INTEGER NOT NULL DEFAULT 0
      );
    ''');
    _db = db;
    return db;
  }

  static Future<int> insert(Measurement measurement) async {
    final db = await _openDb();
    return db.insert('measurements', measurement.toMap());
  }

  static Future<List<Measurement>> fetch({
    DateTime? since,
    DateTime? until,
    int limit = 200,
  }) async {
    final db = await _openDb();
    final where = <String>[];
    final args = <Object>[];
    if (since != null) {
      where.add('ts >= ?');
      args.add(since.millisecondsSinceEpoch);
    }
    if (until != null) {
      where.add('ts <= ?');
      args.add(until.millisecondsSinceEpoch);
    }
    final rows = await db.query(
      'measurements',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'ts DESC',
      limit: limit,
    );
    return rows.map(Measurement.fromMap).toList();
  }
}
