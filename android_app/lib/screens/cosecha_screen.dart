import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../db/local_database.dart';
import '../models/lote.dart';
import '../models/tarifa.dart';
import '../widgets/app_theme.dart';

class CosechaScreen extends StatefulWidget {
  final Map<String, dynamic> trabajador;
  final VoidCallback onSaved;
  const CosechaScreen({super.key, required this.trabajador, required this.onSaved});

  @override
  State<CosechaScreen> createState() => _CosechaScreenState();
}

class _CosechaScreenState extends State<CosechaScreen> {
  List<Lote> _lotes = [];
  Lote? _loteSeleccionado;
  String _tipoCosecha = 'RECOLECTOR_DE_RACIMOS';
  final _racimosCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  bool _saving = false;
  String? _confirmacion;
  double _precioKg = 0;

  @override
  void initState() {
    super.initState();
    _loadLotes();
    _loadTarifa();
  }

  Future<void> _loadLotes() async {
    final zona = widget.trabajador['zona'] as int? ?? 1;
    final rows = await LocalDatabase.getLotesByZona(zona);
    setState(() => _lotes = rows.map(Lote.fromMap).toList());
    if (_lotes.isNotEmpty) setState(() => _loteSeleccionado = _lotes.first);
  }

  Future<void> _loadTarifa() async {
    final zona = widget.trabajador['zona'] as int? ?? 1;
    final rows = await LocalDatabase.getTarifasByZona(zona);
    final tarifas = rows.map(Tarifa.fromMap).toList();
    final tipo = _tipoCosecha == 'RECOLECTOR_DE_RACIMOS' ? 'cosecha_recolector' : 'cosecha_mecanizada';
    final tarifa = tarifas.firstWhere((t) => t.tipoLabor == tipo,
        orElse: () => tarifas.isNotEmpty ? tarifas.first : Tarifa(
          tarifaId: 0, tipoLabor: tipo, fechaInicio: '',
        ));
    setState(() => _precioKg = tarifa.precioPorKg ?? 0);
  }

  double get _estimatedEarnings {
    final kg = double.tryParse(_pesoCtrl.text) ?? 0;
    return kg * _precioKg;
  }

  Future<void> _save() async {
    if (_loteSeleccionado == null) {
      _showError('Selecciona un lote');
      return;
    }
    final racimos = int.tryParse(_racimosCtrl.text);
    if (racimos == null || racimos <= 0) {
      _showError('Ingresa el número de racimos');
      return;
    }

    setState(() => _saving = true);

    final uuid = const Uuid().v4();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    String? deviceId;
    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;
      deviceId = android.id;
    } catch (_) {
      deviceId = 'unknown';
    }

    await LocalDatabase.insertCosecha({
      'cosecha_id': uuid,
      'trabajador_id': widget.trabajador['trabajador_id'],
      'cod_cosechero': widget.trabajador['cod_cosechero'],
      'lote_id': _loteSeleccionado!.loteId,
      'ticket_extractora': null,
      'fecha_corte': today,
      'tipo_cosecha': _tipoCosecha,
      'metodo_recoleccion': _tipoCosecha == 'RECOLECTOR_DE_RACIMOS' ? 'CON_TIJERA' : 'NO_APLICA',
      'total_racimos': racimos,
      'peso_extractora_sin_recolector': double.tryParse(_pesoCtrl.text) ?? 0,
      'total_racimos_recolector': null,
      'peso_extractora_recolector': null,
      'observaciones': null,
      'sync_status': 'pending',
      'created_offline': 1,
      'device_id': deviceId,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });

    setState(() {
      _saving = false;
      _confirmacion = 'Registrado  •  Ganancias estimadas hoy: ${formatCOP(_estimatedEarnings)}';
      _racimosCtrl.clear();
      _pesoCtrl.clear();
    });

    widget.onSaved();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrar Cosecha',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 20),

          if (_confirmacion != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                border: Border.all(color: AppColors.success),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_confirmacion!,
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold))),
                ],
              ),
            ),

          // Lote selector
          const Text('Lote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Lote>(
            value: _loteSeleccionado,
            isExpanded: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.map)),
            items: _lotes.map((l) => DropdownMenuItem(
              value: l,
              child: Text(l.displayName, style: const TextStyle(fontSize: 16)),
            )).toList(),
            onChanged: (l) => setState(() => _loteSeleccionado = l),
          ),
          const SizedBox(height: 20),

          // Tipo cosecha toggle
          const Text('Tipo de cosecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'RECOLECTOR_DE_RACIMOS', label: Text('Con Recolector')),
              ButtonSegment(value: 'MECANIZADA', label: Text('Mecanizada')),
            ],
            selected: {_tipoCosecha},
            onSelectionChanged: (s) {
              setState(() => _tipoCosecha = s.first);
              _loadTarifa();
            },
          ),
          const SizedBox(height: 20),

          // Racimos input
          const Text('Total racimos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _racimosCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '0',
              prefixIcon: Icon(Icons.grain),
              suffixText: 'racimos',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Peso input
          const Text('Peso extractora (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _pesoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '0.0',
              prefixIcon: Icon(Icons.scale),
              suffixText: 'kg',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // Live earnings preview
          if (_pesoCtrl.text.isNotEmpty && _precioKg > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ganancia estimada:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatCOP(_estimatedEarnings),
                      style: const TextStyle(
                          color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 24),
            label: const Text('GUARDAR COSECHA', style: TextStyle(fontSize: 18)),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
