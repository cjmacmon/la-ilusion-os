import 'package:flutter/material.dart';
import '../db/local_database.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../widgets/app_theme.dart';

class SincronizacionScreen extends StatefulWidget {
  final Future<void> Function() onSync;
  const SincronizacionScreen({super.key, required this.onSync});

  @override
  State<SincronizacionScreen> createState() => _SincronizacionScreenState();
}

class _SincronizacionScreenState extends State<SincronizacionScreen> {
  bool _isOnline = false;
  bool _syncing = false;
  int _pendingCosecha = 0;
  int _pendingFert = 0;
  DateTime? _lastSync;
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    ConnectivityService.onConnectivityChanged.listen((online) {
      setState(() => _isOnline = online);
    });
    ConnectivityService.isOnline().then((v) => setState(() => _isOnline = v));
  }

  Future<void> _refresh() async {
    final cosecha = await LocalDatabase.getPendingCosechaCount();
    final fert = await LocalDatabase.getPendingFertilizacionCount();
    final lastSync = await SyncService.getLastSync();
    setState(() {
      _pendingCosecha = cosecha;
      _pendingFert = fert;
      _lastSync = lastSync;
    });
  }

  Future<void> _sync() async {
    if (!_isOnline) {
      setState(() => _log.insert(0, '${_ts()} Sin conexión — sync cancelado'));
      return;
    }
    setState(() => _syncing = true);
    final result = await SyncService.sync();
    await widget.onSync();
    await _refresh();

    if (result != null) {
      setState(() {
        _log.insert(0,
            '${_ts()} Cosecha: ${result.cosechaSynced} enviados, ${result.cosechaDuplicates} duplicados | '
            'Fert: ${result.fertSynced} enviados');
        if (result.errors.isNotEmpty) {
          _log.insert(0, '${_ts()} Errores: ${result.errors.join(', ')}');
        }
        if (_log.length > 5) _log.removeRange(5, _log.length);
        _syncing = false;
      });
    } else {
      setState(() {
        _log.insert(0, '${_ts()} Sync falló — sin token');
        _syncing = false;
      });
    }
  }

  String _ts() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sincronización',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 20),

          // Connectivity status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isOnline ? AppColors.success.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isOnline ? AppColors.success : AppColors.error),
            ),
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? AppColors.success : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _isOnline ? 'Conectado a internet' : 'Sin señal',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _isOnline ? AppColors.success : AppColors.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pending counts
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _pendingRow('Cosechas pendientes', _pendingCosecha),
                  const Divider(),
                  _pendingRow('Fertilizaciones pendientes', _pendingFert),
                  if (_lastSync != null) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Última sincronización',
                            style: TextStyle(color: AppColors.textSecondary)),
                        Text(_formatDateTime(_lastSync!),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            icon: _syncing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.sync, size: 24),
            label: Text(_syncing ? 'Sincronizando...' : 'SINCRONIZAR AHORA',
                style: const TextStyle(fontSize: 18)),
            onPressed: (_syncing || !_isOnline) ? null : _sync,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isOnline ? AppColors.primary : Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          if (_log.isNotEmpty) ...[
            const Text('Registro de sincronizaciones',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._log.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(entry, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                )),
          ],
        ],
      ),
    );
  }

  Widget _pendingRow(String label, int count) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: count > 0 ? AppColors.accent.withOpacity(0.2) : AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: count > 0 ? AppColors.accentDark : AppColors.success),
              ),
            ),
          ],
        ),
      );

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}
