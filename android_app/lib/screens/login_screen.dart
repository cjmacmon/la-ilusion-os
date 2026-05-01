import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../db/local_database.dart';
import '../widgets/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // Step 0 = enter code, Step 1 = enter PIN
  int _step = 0;
  String _cod = '';
  String _pin = '';
  bool _loading = false;
  String? _error;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onCodeKey(String key) {
    if (key == '⌫') {
      setState(() { if (_cod.isNotEmpty) _cod = _cod.substring(0, _cod.length - 1); _error = null; });
    } else if (_cod.length < 8) {
      setState(() { _cod = (_cod + key).toUpperCase(); _error = null; });
    }
  }

  void _onPinKey(String key) {
    if (key == '⌫') {
      setState(() { if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1); _error = null; });
    } else if (_pin.length < 4) {
      final newPin = _pin + key;
      setState(() { _pin = newPin; _error = null; });
      if (newPin.length == 4) _login(newPin);
    }
  }

  Future<void> _login(String pin) async {
    setState(() { _loading = true; _error = null; });
    Map<String, dynamic>? trabajador;

    if (kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.apiBaseUrl}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'cod_cosechero': _cod, 'pin': pin}),
        ).timeout(ApiConfig.timeout);

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final data = body['data'] as Map<String, dynamic>;
          final token = data['token'] as String;
          final t = data['trabajador'] as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('current_worker_id', t['trabajador_id'] as String);
          await prefs.setString('current_worker_cod', t['cod_cosechero'] as String);
          trabajador = t;
        } else {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          _showError(body['error'] as String? ?? 'Código o PIN incorrecto');
          return;
        }
      } catch (e) {
        _showError('Sin conexión. Intenta de nuevo.');
        return;
      }
    } else {
      trabajador = await LocalDatabase.getTrabajadorByCod(_cod);
      if (trabajador == null) { _showError('Código no encontrado'); return; }
      if (trabajador['pin'] != pin) { _showError('PIN incorrecto'); return; }
      if ((trabajador['activo'] as int) != 1) { _showError('Usuario inactivo'); return; }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_worker_id', trabajador['trabajador_id'] as String);
      await prefs.setString('current_worker_cod', trabajador['cod_cosechero'] as String);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(trabajador: trabajador!)),
    );
  }

  void _showError(String msg) {
    setState(() { _loading = false; _error = msg; _pin = ''; });
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: _step == 0 ? _buildCodeStep() : _buildPinStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
    children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: const Icon(Icons.grass, size: 48, color: Colors.white),
      ),
      const SizedBox(height: 12),
      const Text('La Ilusión', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1)),
      const Text('Hacienda Palmera', style: TextStyle(color: Colors.white54, fontSize: 15)),
    ],
  );

  Widget _buildCodeStep() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('¿Cuál es tu código?', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text('Está en tu carnet de trabajo', style: TextStyle(color: Colors.white60, fontSize: 16), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white30, width: 1.5),
          ),
          child: Text(
            _cod.isEmpty ? 'HLI___' : _cod,
            style: TextStyle(
              color: _cod.isEmpty ? Colors.white30 : Colors.white,
              fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _buildError(),
        ],
        const SizedBox(height: 16),
        Expanded(child: _buildAlphaKeypad()),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _cod.length >= 3 ? () => setState(() => _step = 1) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CONTINUAR →', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinStep() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('Hola, $_cod', style: const TextStyle(color: Colors.white70, fontSize: 18)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('Ingresa tu PIN', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ),
        const SizedBox(height: 4),
        const Text('4 números secretos', style: TextStyle(color: Colors.white54, fontSize: 15)),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(_shakeAnim.value * 10 * ((_shakeAnim.value * 10).toInt() % 2 == 0 ? 1 : -1), 0),
            child: child,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length
                    ? (_error != null ? AppColors.error : AppColors.accent)
                    : Colors.white24,
              ),
            )),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _buildError(),
        ],
        const SizedBox(height: 16),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)))
        else
          Expanded(child: _buildPinKeypad()),
        TextButton(
          onPressed: () => setState(() { _step = 0; _pin = ''; _error = null; }),
          child: const Text('← Cambiar código', style: TextStyle(color: Colors.white54, fontSize: 16)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildError() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.warning_rounded, color: AppColors.error, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
      ]),
    ),
  );

  Widget _buildPinKeypad() {
    final keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      mainAxisSpacing: 10, crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      physics: const NeverScrollableScrollPhysics(),
      children: keys.map((k) => k.isEmpty
          ? const SizedBox()
          : _keyButton(k, () => _onPinKey(k))).toList(),
    );
  }

  Widget _buildAlphaKeypad() {
    final rows = [
      ['1','2','3','4','5','6','7','8','9','0'],
      ['H','L','I','A','B','C','D','E','F','G'],
      ['J','K','M','N','O','P','Q','R','S','T'],
      ['U','V','W','X','Y','Z','⌫'],
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      children: rows.map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: row.map((k) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: SizedBox(height: 46, child: _keyButton(k, () => _onCodeKey(k))),
            ),
          )).toList(),
        ),
      )).toList(),
    );
  }

  Widget _keyButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: label == '⌫' ? Colors.white10 : Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(
        color: label == '⌫' ? Colors.white54 : Colors.white,
        fontSize: 22, fontWeight: FontWeight.bold,
      )),
    ),
  );
}
