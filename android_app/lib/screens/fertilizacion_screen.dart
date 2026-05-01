import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../db/local_database.dart';
import '../models/lote.dart';
import '../models/tarifa.dart';
import '../widgets/app_theme.dart';

class FertilizacionScreen extends StatefulWidget {
  final Map<String, dynamic> trabajador;
  final VoidCallback onSaved;
  const FertilizacionScreen({super.key, required this.trabajador, required this.onSaved});

  @override
  State<FertilizacionScreen> createState() => _FertilizacionScreenState();
}

class _FertilizacionScreenState extends State<FertilizacionScreen> {
  List<Lote> _lotes = [];
  Lote? _loteSeleccionado;
  final _palmasCtrl = TextEditingController();
  final _dosisCtrl = TextEditingController(text: '2.5');
  bool _saving = false;
  String? _confirmacion;
  double _precioUnidad = 0;

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
    final tarifa = tarifas.firstWhere((t) => t.tipoLabor == 'fertilizacion',
        orElse: () => Tarifa(tarifaId: 0, tipoLabor: 'fertilizacion', fechaInicio: ''));
    setState(() => _precioUnidad = tarifa.precioPorUnidad ?? 0);
  }

  double get _totalAplicado {
    final palmas = double.tryParse(_palmasCtrl.text) ?? 0;
    final dosis = double.tryParse(_dosisCtrl.text) ?? 0;
    return palmas * dosis;
  }

  double get _estimatedEarnings => _totalAplicado * _precioUnidad;

  Future<void> _save() async {
    if (_loteSeleccionado == null) {
      _showError('Selecciona un lote');
      return;
    }
    final palmas = int.tryParse(_palmasCtrl.text);
    if (palmas == null || palmas <= 0) {
      _showError('Ingresa el número de palmas fertilizadas');
      return;
    }
    final dosis = double.tryParse(_dosisCtrl.text) ?? 0;

    setState(() => _saving = true);

    final uuid = const Uuid().v4();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    await LocalDatabase.insertFertilizacion({
      'fertilizacion_id': uuid,
      'trabajador_id': widget.trabajador['trabajador_id'],
      'lote_id': _loteSeleccionado!.loteId,
      'fecha': today,
      'palmas_fertilizadas': palmas,
      'dosis_por_palma': dosis,
      'total_aplicado': _totalAplicado,
      'observaciones': null,
      'sync_status': 'pending',
      'device_id': null,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });

    setState(() {
      _saving = false;
      _confirmacion = 'Registrado  •  Ganancias estimadas: ${formatCOP(_estimatedEarnings)}';
      _palmasCtrl.clear();
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
          const Text('Registrar Fertilización',
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

          const Text('Palmas fertilizadas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _palmasCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: '0',
              prefixIcon: Icon(Icons.eco),
              suffixText: 'palmas',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          const Text('Dosis por palma (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _dosisCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.opacity),
              suffixText: 'kg/palma',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          if (_palmasCtrl.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total aplicado:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_totalAplicado.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 8),
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
          ],
          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 24),
            label: const Text('GUARDAR FERTILIZACIÓN', style: TextStyle(fontSize: 18)),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
