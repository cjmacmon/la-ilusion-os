import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../db/local_database.dart';

class SeedService {
  static Future<bool> seedFromServer(String token) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.apiBaseUrl}/lotes'), headers: headers)
            .timeout(ApiConfig.timeout),
        http.get(Uri.parse('${ApiConfig.apiBaseUrl}/tarifas'), headers: headers)
            .timeout(ApiConfig.timeout),
        http.get(Uri.parse('${ApiConfig.apiBaseUrl}/incentivos'), headers: headers)
            .timeout(ApiConfig.timeout),
        http.get(Uri.parse('${ApiConfig.apiBaseUrl}/trabajadores?activo=true'), headers: headers)
            .timeout(ApiConfig.timeout),
      ]);

      final lotes = jsonDecode(results[0].body)['data'] as List;
      final tarifas = jsonDecode(results[1].body)['data'] as List;
      final incentivos = jsonDecode(results[2].body)['data'] as List;
      final trabajadores = jsonDecode(results[3].body)['data'] as List;

      for (final l in lotes) {
        await LocalDatabase.upsertLote({
          'lote_id': l['lote_id'],
          'cod_lote': l['cod_lote'],
          'nombre': l['nombre'],
          'zona': l['zona'],
          'hectareas': l['hectareas'],
          'numero_palmas': l['numero_palmas'],
          'peso_promedio_kg': l['peso_promedio_kg'],
          'anio_siembra': l['anio_siembra'],
        });
      }

      for (final t in tarifas) {
        await LocalDatabase.upsertTarifa({
          'tarifa_id': t['tarifa_id'],
          'tipo_labor': t['tipo_labor'],
          'zona': t['zona'],
          'precio_por_kg': t['precio_por_kg'],
          'precio_por_unidad': t['precio_por_unidad'],
          'fecha_inicio': t['fecha_inicio'],
        });
      }

      for (final i in incentivos) {
        await LocalDatabase.upsertIncentivo({
          'incentivo_id': i['incentivo_id'],
          'nombre': i['nombre'],
          'tipo': i['tipo'],
          'umbral': i['umbral'],
          'monto_bono': i['monto_bono'],
          'activo': i['activo'] == true ? 1 : 0,
          'descripcion': i['descripcion'],
        });
      }

      for (final w in trabajadores) {
        await LocalDatabase.upsertTrabajador({
          'trabajador_id': w['trabajador_id'],
          'cod_cosechero': w['cod_cosechero'],
          'cedula': w['cedula'],
          'nombre_completo': w['nombre_completo'],
          'telefono': w['telefono'],
          'pin': w['pin'] ?? '0000',
          'rol': w['rol'],
          'zona': w['zona'],
          'activo': w['activo'] == true ? 1 : 0,
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('seed_date', DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> needsSeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('seed_date') == null;
  }
}
