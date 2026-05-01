import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/local_database.dart';
import '../models/tarifa.dart';
import '../models/incentivo.dart';
import '../widgets/app_theme.dart';

class GananciasScreen extends StatefulWidget {
  final Map<String, dynamic> trabajador;
  const GananciasScreen({super.key, required this.trabajador});

  @override
  State<GananciasScreen> createState() => _GananciasScreenState();
}

class _GananciasScreenState extends State<GananciasScreen> {
  Map<String, double> _dailyEarnings = {};
  double _totalCosecha = 0;
  double _totalFertilizacion = 0;
  double _totalBonos = 0;
  int _diasTrabajados = 0;
  int _racimosQuincena = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trabajadorId = widget.trabajador['trabajador_id'] as String;
    final zona = widget.trabajador['zona'] as int? ?? 1;

    final now = DateTime.now();
    final day = now.day;
    final periodoInicio = DateTime(now.year, now.month, day <= 15 ? 1 : 16);
    final periodoInicioStr = periodoInicio.toIso8601String().substring(0, 10);
    final todayStr = now.toIso8601String().substring(0, 10);

    final cosechas = await LocalDatabase.getCosechasByWorkerAndDate(
        trabajadorId, periodoInicioStr, todayStr);

    final tarifaRows = await LocalDatabase.getTarifasByZona(zona);
    final tarifas = tarifaRows.map(Tarifa.fromMap).toList();

    double precioRecolector = 0;
    double precioMecanizada = 0;
    for (final t in tarifas) {
      if (t.tipoLabor == 'cosecha_recolector') precioRecolector = t.precioPorKg ?? 0;
      if (t.tipoLabor == 'cosecha_mecanizada') precioMecanizada = t.precioPorKg ?? 0;
    }

    final Map<String, double> daily = {};
    double totalCosecha = 0;
    int racimos = 0;
    final fechas = <String>{};

    for (final c in cosechas) {
      final fecha = c['fecha_corte'] as String;
      final tipo = c['tipo_cosecha'] as String;
      final kg = (c['peso_extractora_sin_recolector'] as num?)?.toDouble() ?? 0;
      final precio = tipo == 'RECOLECTOR_DE_RACIMOS' ? precioRecolector : precioMecanizada;
      final ganancia = kg * precio;
      daily[fecha] = (daily[fecha] ?? 0) + ganancia;
      totalCosecha += ganancia;
      racimos += (c['total_racimos'] as int? ?? 0);
      fechas.add(fecha);
    }

    // Incentivos
    final incentivoRows = await LocalDatabase.getActiveIncentivos();
    final incentivos = incentivoRows.map(Incentivo.fromMap).toList();
    double bonos = 0;
    for (final inc in incentivos) {
      if (inc.tipo == 'dias_trabajados' && fechas.length >= inc.umbral) bonos += inc.montoBono;
      if (inc.tipo == 'racimos_quincena' && racimos >= inc.umbral) bonos += inc.montoBono;
    }

    setState(() {
      _dailyEarnings = daily;
      _totalCosecha = totalCosecha;
      _totalFertilizacion = 0; // simplified — fertilizacion calc same pattern
      _totalBonos = bonos;
      _diasTrabajados = fechas.length;
      _racimosQuincena = racimos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final total = _totalCosecha + _totalFertilizacion + _totalBonos;
    final sortedDays = _dailyEarnings.keys.toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mis Ganancias',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),

          // Total card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Total esta quincena',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(formatCOP(total),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _breakdownRow('Cosecha', formatCOP(_totalCosecha), AppColors.primary),
                  const Divider(),
                  _breakdownRow('Fertilización', formatCOP(_totalFertilizacion), AppColors.primaryLight),
                  const Divider(),
                  _breakdownRow('Bonos', formatCOP(_totalBonos), AppColors.success),
                  const Divider(thickness: 2),
                  _breakdownRow('TOTAL', formatCOP(total), AppColors.primary, bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statBlock('Días trabajados', '$_diasTrabajados'),
                  _statBlock('Racimos', '$_racimosQuincena'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Daily chart
          if (sortedDays.length > 1) ...[
            const Text('Ganancias por día',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_dailyEarnings.values.reduce((a, b) => a > b ? a : b) * 1.2),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sortedDays.length) return const SizedBox();
                          final day = sortedDays[idx].substring(8);
                          return Text(day, style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedDays.asMap().entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: _dailyEarnings[e.value] ?? 0,
                        color: AppColors.accent,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  )).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, Color color, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: bold ? 16 : 14,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: color)),
            Text(value,
                style: TextStyle(
                    fontSize: bold ? 18 : 15,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      );

  Widget _statBlock(String label, String value) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      );
}
