import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../db/local_database.dart';

class GamificationData {
  final int racimosHoy;
  final double kgHoy;
  final int gananciasHoyCop;
  final int gananciasQuincenaCop;
  final int diasTrabajadosQuincena;
  final int racimosQuincena;
  final Map<String, dynamic>? proximoBono;
  final int? posicionLeaderboard;
  final List<Map<String, dynamic>> leaderboardTop7;

  const GamificationData({
    required this.racimosHoy,
    required this.kgHoy,
    required this.gananciasHoyCop,
    required this.gananciasQuincenaCop,
    required this.diasTrabajadosQuincena,
    required this.racimosQuincena,
    this.proximoBono,
    this.posicionLeaderboard,
    required this.leaderboardTop7,
  });
}

class GamificationService {
  // Fetch from server and cache locally
  static Future<GamificationData?> fetchFromServer(String codCosechero, String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.apiBaseUrl}/gamificacion/$codCosechero/hoy'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as Map<String, dynamic>;
        await _cacheGamification(data);
        return _fromMap(data);
      }
    } catch (_) {}
    return null;
  }

  // Calculate locally from SQLite (offline fallback)
  static Future<GamificationData> calculateLocally(
      String trabajadorId, int zona) async {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().substring(0, 10);

    final day = today.day;
    final periodoInicio = DateTime(today.year, today.month, day <= 15 ? 1 : 16);
    final periodoInicioStr = periodoInicio.toIso8601String().substring(0, 10);

    final weekAgo = today.subtract(const Duration(days: 7));
    final weekAgoStr = weekAgo.toIso8601String().substring(0, 10);

    // Today's records
    final todayCosechas = await LocalDatabase.getCosechasByWorkerAndDate(
        trabajadorId, todayStr, todayStr);
    int racimosHoy = 0;
    double kgHoy = 0;
    for (final c in todayCosechas) {
      racimosHoy += (c['total_racimos'] as int? ?? 0);
      kgHoy += (c['peso_extractora_sin_recolector'] as num?)?.toDouble() ?? 0;
    }

    // Quincena records
    final quincenaCosechas = await LocalDatabase.getCosechasByWorkerAndDate(
        trabajadorId, periodoInicioStr, todayStr);
    int racimosQuincena = 0;
    double kgQuincena = 0;
    final fechasTrabajadas = <String>{};
    for (final c in quincenaCosechas) {
      racimosQuincena += (c['total_racimos'] as int? ?? 0);
      kgQuincena += (c['peso_extractora_sin_recolector'] as num?)?.toDouble() ?? 0;
      fechasTrabajadas.add(c['fecha_corte'] as String);
    }
    final diasTrabajados = fechasTrabajadas.length;

    // Get tarifa for zona
    final tarifas = await LocalDatabase.getTarifasByZona(zona);
    double precioKg = 0;
    for (final t in tarifas) {
      if (t['tipo_labor'] == 'cosecha_recolector' || t['tipo_labor'] == 'cosecha_mecanizada') {
        if (t['precio_por_kg'] != null) {
          precioKg = (t['precio_por_kg'] as num).toDouble();
          break;
        }
      }
    }

    final gananciasHoy = (kgHoy * precioKg).round();
    final gananciasQuincena = (kgQuincena * precioKg).round();

    // Incentivos
    final incentivos = await LocalDatabase.getActiveIncentivos();
    Map<String, dynamic>? proximoBono;
    for (final inc in incentivos) {
      final umbral = (inc['umbral'] as num).toDouble();
      if (inc['tipo'] == 'dias_trabajados' && diasTrabajados < umbral) {
        proximoBono = {
          'nombre': inc['nombre'],
          'umbral': umbral,
          'progreso': diasTrabajados.toDouble(),
          'monto_cop': (inc['monto_bono'] as num).toDouble(),
          'tipo': inc['tipo'],
        };
        break;
      } else if (inc['tipo'] == 'racimos_quincena' && racimosQuincena < umbral) {
        proximoBono ??= {
          'nombre': inc['nombre'],
          'umbral': umbral,
          'progreso': racimosQuincena.toDouble(),
          'monto_cop': (inc['monto_bono'] as num).toDouble(),
          'tipo': inc['tipo'],
        };
      }
    }

    return GamificationData(
      racimosHoy: racimosHoy,
      kgHoy: kgHoy,
      gananciasHoyCop: gananciasHoy,
      gananciasQuincenaCop: gananciasQuincena,
      diasTrabajadosQuincena: diasTrabajados,
      racimosQuincena: racimosQuincena,
      proximoBono: proximoBono,
      posicionLeaderboard: null,
      leaderboardTop7: const [],
    );
  }

  static GamificationData _fromMap(Map<String, dynamic> d) => GamificationData(
        racimosHoy: d['racimos_hoy'] as int? ?? 0,
        kgHoy: (d['kg_hoy'] as num?)?.toDouble() ?? 0,
        gananciasHoyCop: d['ganancias_hoy_cop'] as int? ?? 0,
        gananciasQuincenaCop: d['ganancias_quincena_cop'] as int? ?? 0,
        diasTrabajadosQuincena: d['dias_trabajados_quincena'] as int? ?? 0,
        racimosQuincena: d['racimos_quincena'] as int? ?? 0,
        proximoBono: d['proximo_bono'] as Map<String, dynamic>?,
        posicionLeaderboard: d['posicion_leaderboard'] as int?,
        leaderboardTop7: (d['leaderboard_top7'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );

  static Future<void> _cacheGamification(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gamification_cache', jsonEncode(data));
    await prefs.setString('gamification_cache_time', DateTime.now().toIso8601String());
  }

  static Future<GamificationData?> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('gamification_cache');
    if (raw == null) return null;
    return _fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }
}
