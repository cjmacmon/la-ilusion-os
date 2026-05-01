import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/local_database.dart';
import '../widgets/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codController = TextEditingController();
  final _pinController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final cod = _codController.text.trim().toUpperCase();
    final pin = _pinController.text.trim();

    if (cod.isEmpty || pin.isEmpty) {
      setState(() => _error = 'Ingresa tu código y PIN');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final trabajador = await LocalDatabase.getTrabajadorByCod(cod);

    if (trabajador == null) {
      setState(() { _loading = false; _error = 'Código no encontrado. Sincroniza con conexión primero.'; });
      return;
    }

    if (trabajador['pin'] != pin) {
      setState(() { _loading = false; _error = 'PIN incorrecto'; });
      return;
    }

    if ((trabajador['activo'] as int) != 1) {
      setState(() { _loading = false; _error = 'Usuario inactivo'; });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_worker_id', trabajador['trabajador_id'] as String);
    await prefs.setString('current_worker_cod', trabajador['cod_cosechero'] as String);
    await prefs.setString('current_worker_name', trabajador['nombre_completo'] as String);
    await prefs.setString('current_worker_rol', trabajador['rol'] as String);
    await prefs.setInt('current_worker_zona', trabajador['zona'] as int? ?? 1);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(trabajador: trabajador)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo / Header
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.agriculture, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hacienda La Ilusión',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Sistema de Gestión',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              // Login card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingresa al sistema',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'Código de cosechero',
                        hintText: 'Ej: HLI050',
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 12),
                      decoration: const InputDecoration(
                        labelText: 'PIN (4 dígitos)',
                        prefixIcon: Icon(Icons.lock),
                        counterText: '',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('ENTRAR', style: TextStyle(fontSize: 20, letterSpacing: 2)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Funciona sin conexión a internet',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
