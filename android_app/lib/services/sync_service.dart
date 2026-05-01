import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../db/local_database.dart';

class SyncResult {
  final int cosechaSynced;
  final int cosechaDuplicates;
  final int fertSynced;
  final int fertDuplicates;
  final List<String> errors;
  final DateTime timestamp;

  const SyncResult({
    required this.cosechaSynced,
    required this.cosechaDuplicates,
    required this.fertSynced,
    required this.fertDuplicates,
    required this.errors,
    required this.timestamp,
  });
}

class SyncService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<SyncResult?> sync() async {
    final token = await _getToken();
    if (token == null) return null;

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    int cosechaSynced = 0;
    int cosechaDuplicates = 0;
    int fertSynced = 0;
    int fertDuplicates = 0;
    final errors = <String>[];

    // ── COSECHA SYNC ──────────────────────────────────────
    final pendingCosechas = await LocalDatabase.getPendingCosechas();
    if (pendingCosechas.isNotEmpty) {
      try {
        final response = await http
            .post(
              Uri.parse('${ApiConfig.apiBaseUrl}/cosecha/sync'),
              headers: headers,
              body: jsonEncode({'records': pendingCosechas}),
            )
            .timeout(ApiConfig.timeout);

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final data = body['data'];
          cosechaSynced = data['synced'] as int? ?? 0;
          cosechaDuplicates = data['duplicates'] as int? ?? 0;

          for (final r in pendingCosechas) {
            await LocalDatabase.markCosechaSynced(r['cosecha_id'] as String);
          }
        } else {
          errors.add('Cosecha sync falló: ${response.statusCode}');
        }
      } catch (e) {
        errors.add('Cosecha sync error: $e');
      }
    }

    // ── FERTILIZACION SYNC ────────────────────────────────
    final pendingFert = await LocalDatabase.getPendingFertilizaciones();
    if (pendingFert.isNotEmpty) {
      try {
        final response = await http
            .post(
              Uri.parse('${ApiConfig.apiBaseUrl}/fertilizacion/sync'),
              headers: headers,
              body: jsonEncode({'records': pendingFert}),
            )
            .timeout(ApiConfig.timeout);

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          final data = body['data'];
          fertSynced = data['synced'] as int? ?? 0;
          fertDuplicates = data['duplicates'] as int? ?? 0;

          for (final r in pendingFert) {
            await LocalDatabase.markFertilizacionSynced(r['fertilizacion_id'] as String);
          }
        } else {
          errors.add('Fertilización sync falló: ${response.statusCode}');
        }
      } catch (e) {
        errors.add('Fertilización sync error: $e');
      }
    }

    final result = SyncResult(
      cosechaSynced: cosechaSynced,
      cosechaDuplicates: cosechaDuplicates,
      fertSynced: fertSynced,
      fertDuplicates: fertDuplicates,
      errors: errors,
      timestamp: DateTime.now(),
    );

    // Persist last sync time
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync', DateTime.now().toIso8601String());

    return result;
  }

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('last_sync');
    return raw != null ? DateTime.tryParse(raw) : null;
  }
}
