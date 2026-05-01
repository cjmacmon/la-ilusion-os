import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
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
  double _totalCosecha = 0;
  double _totalFertilizacion = 0;
  double _totalBonos = 0;
  int _diasTrabajados = 0;
  int _racimosQuincena = 0;
  double _gananciasHoy = 0;
  bool _loading = true;
  Map<String, dynamic>? _proximoBono;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (kIsWeb) {
      await _loadFromApi();
    } else {
      await _loadFromLocal();
    }
  }

  Future<void> _loadFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final cod = widget.trabajador['cod_cosechero'] as String;

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/gamificacion/$cod/hoy'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = (jsonDecode(response.body) as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        setState(() {
          _gananciasHoy = (data['ganancias_hoy_cop'] as num?)?.toDouble() ?? 0;
          _totalCosecha = (data['ganancias_quincena_cop'] as num?)?.toDouble() ?? 0;
          _totalBonos = 0;
          _diasTrabajados = (data['dias_trabajados_quincena'] as int?) ?? 0;
          _racimosQuincena = (data['racimos_quincena'] as int?) ?? 0;
          _proximoBono = data['proximo_bono'] as Map<String, dynamic>?;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadFromLocal() async {
    final trabajadorId = widget.trabajador['trabajador_id'] as String;
    final zona = widget.trabajador['zona'] as int? ?? 1;
    final now = DateTime.now();
    final day = now.day;
    final periodoInicio = DateTime(now.year, now.month, day <= 15 ? 1 : 16);
    final periodoInicioStr = periodoInicio.toIso8601String().substring(0, 10);
    final todayStr = now.toIso8601String().substring(0, 10);

    final cosechas = await LocalDatabase.getCosechasByWorkerAndDate(trabajadorId, periodoInicioStr, todayStr);
    final tarifaRows = await LocalDatabase.getTarifasByZona(zona);
    final tarifas = tarifaRows.map(Tarifa.fromMap).toList();

    double precioRecolector = 0, precioMecanizada = 0;
    for (final t in tarifas) {
      if (t.tipoLabor == 'cosecha_recolector') precioRecolector = t.precioPorKg ?? 0;
      if (t.tipoLabor == 'cosecha_mecanizada') precioMecanizada = t.precioPorKg ?? 0;
    }

    double totalCosecha = 0, gananciasHoy = 0;
    int racimos = 0;
    final fechas = <String>{};

    for (final c in cosechas) {
      final fecha = c['fecha_corte'] as String;
      final tipo = c['tipo_cosecha'] as String;
      final kg = (c['peso_extractora_sin_recolector'] as num?)?.toDouble() ?? 0;
      final precio = tipo == 'RECOLECTOR_DE_RACIMOS' ? precioRecolector : precioMecanizada;
      final ganancia = kg * precio;
      totalCosecha += ganancia;
      if (fecha == todayStr) gananciasHoy += ganancia;
      racimos += (c['total_racimos'] as int? ?? 0);
      fechas.add(fecha);
    }

    final incentivoRows = await LocalDatabase.getActiveIncentivos();
    final incentivos = incentivoRows.map(Incentivo.fromMap).toList();
    double bonos = 0;
    for (final inc in incentivos) {
      if (inc.tipo == 'dias_trabajados' && fechas.length >= inc.umbral) bonos += inc.montoBono;
      if (inc.tipo == 'racimos_quincena' && racimos >= inc.umbral) bonos += inc.montoBono;
    }

    setState(() {
      _gananciasHoy = gananciasHoy;
      _totalCosecha = totalCosecha;
      _totalFertilizacion = 0;
      _totalBonos = bonos;
      _diasTrabajados = fechas.length;
      _racimosQuincena = racimos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final total = _totalCosecha + _totalFertilizacion + _totalBonos;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accent,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildHeroToday()),
            SliverToBoxAdapter(child: _buildQuincenaTotal(total)),
            SliverToBoxAdapter(child: _buildBreakdown()),
            SliverToBoxAdapter(child: _buildStats()),
            if (_proximoBono != null)
              SliverToBoxAdapter(child: _buildBonoProgress()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: AppColors.primary,
    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
    child: const Row(
      children: [
        Text('💰', style: TextStyle(fontSize: 28)),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mis Ganancias', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text('Quincena actual', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ],
    ),
  );

  Widget _buildHeroToday() => Container(
    color: AppColors.primary,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
    child: Column(
      children: [
        const Text('GANASTE HOY', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 6),
        Text(formatCOP(_gananciasHoy),
            style: const TextStyle(color: AppColors.accent, fontSize: 48, fontWeight: FontWeight.w900)),
      ],
    ),
  );

  Widget _buildQuincenaTotal(double total) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(
      children: [
        const Text('TOTAL ESTA QUINCENA', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text(formatCOP(total),
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('${_diasTrabajados} días trabajados · ${_racimosQuincena} racimos',
            style: const TextStyle(color: Colors.white60, fontSize: 14)),
      ],
    ),
  );

  Widget _buildBreakdown() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Column(
      children: [
        _breakdownTile('🌿', 'Cosecha', _totalCosecha, AppColors.primary),
        if (_totalFertilizacion > 0) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          _breakdownTile('🌱', 'Fertilización', _totalFertilizacion, AppColors.primaryLight),
        ],
        if (_totalBonos > 0) ...[
          const Divider(height: 1, indent: 16, endIndent: 16),
          _breakdownTile('🏆', 'Bonos', _totalBonos, AppColors.success),
        ],
      ],
    ),
  );

  Widget _breakdownTile(String emoji, String label, double amount, Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 17, color: AppColors.textSecondary)),
        const Spacer(),
        Text(formatCOP(amount), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    ),
  );

  Widget _buildStats() => Row(
    children: [
      Expanded(child: _statCard('📆', '$_diasTrabajados', 'días\ntrabajados')),
      Expanded(child: _statCard('🌴', '$_racimosQuincena', 'racimos\ncosechados')),
    ],
  );

  Widget _statCard(String emoji, String value, String label) => Container(
    margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _buildBonoProgress() {
    final bono = _proximoBono!;
    final progreso = (bono['progreso'] as num).toDouble();
    final umbral = (bono['umbral'] as num).toDouble();
    final pct = (progreso / umbral).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🎯', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('Próximo bono', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const Spacer(),
            Text(formatCOP(bono['monto_cop'] as num),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.success)),
          ]),
          const SizedBox(height: 6),
          Text(bono['nombre'] as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 14),
          Stack(children: [
            Container(height: 16, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8))),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(height: 16, decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentDark]),
                borderRadius: BorderRadius.circular(8),
              )),
            ),
          ]),
          const SizedBox(height: 8),
          Text('${progreso.toInt()} de ${umbral.toInt()} — te faltan ${(umbral - progreso).toInt()} más',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
