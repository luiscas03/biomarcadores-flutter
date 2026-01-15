import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:biomarcadores/data/measurement_store.dart';

enum _RangeFilter { day, week, month, all }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Measurement> _items = [];
  _RangeFilter _range = _RangeFilter.week;
  DateTime? _dateFilter;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    DateTime? since;
    DateTime? until;
    final now = DateTime.now();
    if (_dateFilter != null) {
      final d = _dateFilter!;
      since = DateTime(d.year, d.month, d.day);
      until = DateTime(d.year, d.month, d.day, 23, 59, 59);
    } else {
      switch (_range) {
        case _RangeFilter.day:
          since = now.subtract(const Duration(hours: 24));
          break;
        case _RangeFilter.week:
          since = now.subtract(const Duration(days: 7));
          break;
        case _RangeFilter.month:
          since = now.subtract(const Duration(days: 30));
          break;
        case _RangeFilter.all:
          since = null;
          break;
      }
    }

    final data = await MeasurementStore.fetch(since: since, until: until, limit: 500);
    _items
      ..clear()
      ..addAll(data);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Color _statusColor(int glucose) {
    if (glucose <= 0) return Colors.grey;
    if (glucose < 70 || glucose > 180) return Colors.redAccent;
    return Colors.green;
  }

  String _statusLabel(int glucose) {
    if (glucose <= 0) return "Sin dato";
    if (glucose < 70) return "Bajo";
    if (glucose > 180) return "Alto";
    return "Normal";
  }

  List<FlSpot> _buildSpots() {
    final data = _items.reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].glucose.toDouble()));
    }
    return spots;
  }

  Widget _buildChart() {
    final spots = _buildSpots();
    if (spots.isEmpty) {
      return const Center(child: Text("Sin datos para graficar"));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 50,
        maxY: 220,
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: 70,
            color: Colors.green.withOpacity(0.2),
            strokeWidth: 1,
          ),
          HorizontalLine(
            y: 180,
            color: Colors.orange.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ]),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orangeAccent,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orangeAccent.withOpacity(0.15),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.black87,
            getTooltipItems: (items) {
              return items.map((item) {
                final index = item.x.toInt();
                final data = _items.reversed.toList();
                final m = data[index];
                return LineTooltipItem(
                  "${m.glucose} mg/dL\n${_formatDate(m.ts)}",
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dateFilter = picked);
      await _loadData();
    }
  }

  Future<void> _clearDateFilter() async {
    setState(() => _dateFilter = null);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF7043);
    const bgGradient = LinearGradient(
      colors: [Color(0xFFE0F7FA), Color(0xFFFFF3E0), Color(0xFFFBE9E7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.black87, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Historial de Mediciones',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                      tooltip: 'Buscar por fecha',
                    ),
                    if (_dateFilter != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearDateFilter,
                        tooltip: 'Limpiar filtro',
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text("24h"),
                      selected: _range == _RangeFilter.day && _dateFilter == null,
                      onSelected: (_) async {
                        setState(() {
                          _range = _RangeFilter.day;
                          _dateFilter = null;
                        });
                        await _loadData();
                      },
                    ),
                    ChoiceChip(
                      label: const Text("7d"),
                      selected: _range == _RangeFilter.week && _dateFilter == null,
                      onSelected: (_) async {
                        setState(() {
                          _range = _RangeFilter.week;
                          _dateFilter = null;
                        });
                        await _loadData();
                      },
                    ),
                    ChoiceChip(
                      label: const Text("30d"),
                      selected: _range == _RangeFilter.month && _dateFilter == null,
                      onSelected: (_) async {
                        setState(() {
                          _range = _RangeFilter.month;
                          _dateFilter = null;
                        });
                        await _loadData();
                      },
                    ),
                    ChoiceChip(
                      label: const Text("Todo"),
                      selected: _range == _RangeFilter.all && _dateFilter == null,
                      onSelected: (_) async {
                        setState(() {
                          _range = _RangeFilter.all;
                          _dateFilter = null;
                        });
                        await _loadData();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'Sin mediciones aun',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ve a "Medir" para crear tu primera medicion',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _items.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Container(
                                  height: 200,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: _buildChart(),
                                );
                              }

                              final m = _items[index - 1];
                              return Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: _statusColor(m.glucose),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatDate(m.ts),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                "${m.glucose} mg/dL",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: primaryColor,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                _statusLabel(m.glucose),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: _statusColor(m.glucose),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "BPM: ${m.bpm}  SpO2: ${m.spo2}%",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
