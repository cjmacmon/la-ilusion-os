import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/api_config.dart';
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

// Step flow: 0=lote, 1=tipo, 2=racimos, 3=peso, 4=celebración
class _CosechaScreenState extends State<CosechaScreen> with TickerProviderStateMixin {
  List<Lote> _lotes = [];
  Lote? _loteSeleccionado;
  String _tipoCosecha = 'RECOLECTOR_DE_RACIMOS';
  String _racimos = '';
  String _peso = '';
  bool _saving = false;
  double _precioKg = 0;
  bool _celebrando = false;
  double _gananciaCelebrada = 0;
  late AnimationController _celebCtrl;
  late Animation<double> _celebScale;

  @override
  void initState() {
    super.initState();
    _loadLotes();
    _loadTarifa();
    _celebCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _celebScale = CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _celebCtrl.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _loadLotes() async {
    final zona = widget.trabajador['zona'] as int? ?? 1;
    if (kIsWeb) {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/lotes'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(ApiConfig.timeout);
      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'] as List;
        final lotes = data
            .map((r) => Lote.fromMap(r as Map<String, dynamic>))
            .where((l) => l.zona == zona)
            .toList();
        setState(() {
          _lotes = lotes;
          if (_lotes.isNotEmpty) _loteSeleccionado = _lotes.first;
        });
      }
    } else {
      final rows = await LocalDatabase.getLotesByZona(zona);
      setState(() => _lotes = rows.map(Lote.fromMap).toList());
      if (_lotes.isNotEmpty) setState(() => _loteSeleccionado = _lotes.first);
    }
  }

  Future<void> _loadTarifa() async {
    final zona = widget.trabajador['zona'] as int? ?? 1;
    final tipo = _tipoCosecha == 'RECOLECTOR_DE_RACIMOS' ? 'cosecha_recolector' : 'cosecha_mecanizada';
    if (kIsWeb) {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/tarifas'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(ApiConfig.timeout);
      if (res.statusCode == 200) {
        final data = (jsonDecode(res.body) as Map<String, dynamic>)['data'] as List;
        final tarifas = data
            .map((r) => Tarifa.fromMap(r as Map<String, dynamic>))
            .where((t) => t.zona == zona)
            .toList();
        final tarifa = tarifas.firstWhere((t) => t.tipoLabor == tipo,
            orElse: () => tarifas.isNotEmpty ? tarifas.first : Tarifa(tarifaId: 0, tipoLabor: tipo, fechaInicio: ''));
        setState(() => _precioKg = tarifa.precioPorKg ?? 0);
      }
    } else {
      final rows = await LocalDatabase.getTarifasByZona(zona);
      final tarifas = rows.map(Tarifa.fromMap).toList();
      final tarifa = tarifas.firstWhere((t) => t.tipoLabor == tipo,
          orElse: () => tarifas.isNotEmpty ? tarifas.first : Tarifa(tarifaId: 0, tipoLabor: tipo, fechaInicio: ''));
      setState(() => _precioKg = tarifa.precioPorKg ?? 0);
    }
  }

  double get _estimatedEarnings => (double.tryParse(_peso) ?? 0) * _precioKg;

  Future<void> _save() async {
    if (_loteSeleccionado == null) return;
    final racimos = int.tryParse(_racimos);
    if (racimos == null || racimos <= 0) return;

    setState(() => _saving = true);

    final uuid = const Uuid().v4();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    String? deviceId;
    try {
      if (!kIsWeb) {
        final info = DeviceInfoPlugin();
        final android = await info.androidInfo;
        deviceId = android.id;
      } else {
        deviceId = 'web';
      }
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
      'peso_extractora_sin_recolector': double.tryParse(_peso) ?? 0,
      'total_racimos_recolector': null,
      'peso_extractora_recolector': null,
      'observaciones': null,
      'sync_status': 'pending',
      'created_offline': 1,
      'device_id': deviceId,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });

    final ganancia = _estimatedEarnings;
    setState(() {
      _saving = false;
      _celebrando = true;
      _gananciaCelebrada = ganancia;
      _racimos = '';
      _peso = '';
    });
    _celebCtrl.forward(from: 0);
    widget.onSaved();
  }

  void _numKey(String key) {
    setState(() {
      if (key == '⌫') {
        // handled per field
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_celebrando) return _buildCelebracion();
    return _buildForm();
  }

  Widget _buildCelebracion() => Scaffold(
    backgroundColor: AppColors.primary,
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _celebScale,
              child: const Text('🎉', style: TextStyle(fontSize: 100)),
            ),
            const SizedBox(height: 24),
            const Text('¡GUARDADO!', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('Ganancia estimada hoy:', style: TextStyle(color: Colors.white60, fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              formatCOP(_gananciaCelebrada),
              style: const TextStyle(color: AppColors.accent, fontSize: 52, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () { setState(() => _celebrando = false); _celebCtrl.reset(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('REGISTRAR OTRA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildForm() => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          _buildFormHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('📍 ¿En qué lote trabajaste?', 'Selecciona tu lote de hoy', _buildLoteSelector()),
                  const SizedBox(height: 20),
                  _buildSection('🌴 ¿Cómo cosechaste?', 'El tipo de cosecha', _buildTipoSelector()),
                  const SizedBox(height: 20),
                  _buildSection('🌿 ¿Cuántos racimos?', 'El total de racimos que cortaste', _buildNumInput(_racimos, (v) => setState(() => _racimos = v), 'Ej: 150', 'racimos')),
                  const SizedBox(height: 20),
                  _buildSection('⚖️ ¿Cuántos kilos?', 'El peso que marcó la extractora', _buildNumInput(_peso, (v) => setState(() => _peso = v), 'Ej: 2500', 'kg')),
                  if (_peso.isNotEmpty && _precioKg > 0) ...[
                    const SizedBox(height: 16),
                    _buildEarningsPreview(),
                  ],
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildFormHeader() => Container(
    color: AppColors.primary,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: Row(
      children: [
        const Icon(Icons.grass_rounded, color: AppColors.accent, size: 28),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrar Cosecha', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Llena los datos de hoy', style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ],
    ),
  );

  Widget _buildSection(String title, String hint, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
      Text(hint, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      const SizedBox(height: 10),
      child,
    ],
  );

  Widget _buildLoteSelector() => _lotes.isEmpty
      ? const Center(child: CircularProgressIndicator())
      : Column(
          children: _lotes.map((l) => GestureDetector(
            onTap: () => setState(() => _loteSeleccionado = l),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _loteSeleccionado == l ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _loteSeleccionado == l ? AppColors.primary : Colors.grey.shade200,
                  width: 2,
                ),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Icon(Icons.map_rounded,
                      color: _loteSeleccionado == l ? AppColors.accent : AppColors.textSecondary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.nombre, style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: _loteSeleccionado == l ? Colors.white : AppColors.primary,
                  ))),
                  if (_loteSeleccionado == l)
                    const Icon(Icons.check_circle, color: AppColors.accent, size: 24),
                ],
              ),
            ),
          )).toList(),
        );

  Widget _buildTipoSelector() => Row(
    children: [
      _tipoBtn('RECOLECTOR_DE_RACIMOS', '✂️', 'Con Recolector'),
      const SizedBox(width: 12),
      _tipoBtn('MECANIZADA', '🚜', 'Mecanizada'),
    ],
  );

  Widget _tipoBtn(String val, String emoji, String label) {
    final sel = _tipoCosecha == val;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() => _tipoCosecha = val); _loadTarifa(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 70,
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? AppColors.primary : Colors.grey.shade200, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              Text(label, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold,
                color: sel ? Colors.white : AppColors.primary,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumInput(String value, ValueSetter<String> onChanged, String hint, String unit) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: value.isNotEmpty ? AppColors.primary : Colors.grey.shade200, width: 2),
          ),
          child: Row(
            children: [
              Expanded(child: Text(
                value.isEmpty ? hint : value,
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.bold,
                  color: value.isEmpty ? Colors.grey.shade300 : AppColors.primary,
                ),
              )),
              Text(unit, style: const TextStyle(fontSize: 18, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildMiniKeypad(value, onChanged),
      ],
    );
  }

  Widget _buildMiniKeypad(String current, ValueSetter<String> onChanged) {
    final keys = ['1','2','3','4','5','6','7','8','9','.','0','⌫'];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 6,
      childAspectRatio: 1.4,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: keys.map((k) => GestureDetector(
        onTap: () {
          if (k == '⌫') {
            onChanged(current.isEmpty ? '' : current.substring(0, current.length - 1));
          } else if (k == '.' && current.contains('.')) {
            // ignore double dot
          } else if (current.length < 7) {
            onChanged(current + k);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: k == '⌫' ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: Text(k, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold,
            color: k == '⌫' ? AppColors.error : AppColors.primary,
          )),
        ),
      )).toList(),
    );
  }

  Widget _buildEarningsPreview() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Text('💰', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ganarías aprox.', style: TextStyle(color: Colors.white60, fontSize: 14)),
            Text(formatCOP(_estimatedEarnings),
                style: const TextStyle(color: AppColors.accent, fontSize: 28, fontWeight: FontWeight.w900)),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${formatCOP(_precioKg)}/kg', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const Text('tarifa aplicada', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ],
    ),
  );

  Widget _buildSaveButton() {
    final canSave = _loteSeleccionado != null && _racimos.isNotEmpty && int.tryParse(_racimos) != null;
    return GestureDetector(
      onTap: canSave && !_saving ? _save : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 72,
        decoration: BoxDecoration(
          gradient: canSave
              ? const LinearGradient(colors: [AppColors.accent, AppColors.accentDark])
              : null,
          color: canSave ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: canSave ? [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))] : [],
        ),
        child: Center(
          child: _saving
              ? const CircularProgressIndicator(color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: canSave ? Colors.white : Colors.grey, size: 28),
                    const SizedBox(width: 10),
                    Text('GUARDAR COSECHA',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: canSave ? Colors.white : Colors.grey,
                        )),
                  ],
                ),
        ),
      ),
    );
  }
}
