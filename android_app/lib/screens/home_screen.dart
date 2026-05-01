import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_theme.dart';
import '../services/gamification_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import 'cosecha_screen.dart';
import 'fertilizacion_screen.dart';
import 'ganancias_screen.dart';
import 'leaderboard_screen.dart';
import 'sincronizacion_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> trabajador;
  const HomeScreen({super.key, required this.trabajador});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GamificationData? _gamData;
  bool _isOnline = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    ConnectivityService.onConnectivityChanged.listen((online) {
      setState(() => _isOnline = online);
      if (online) _syncAndRefresh();
    });
    ConnectivityService.isOnline().then((v) => setState(() => _isOnline = v));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final cod = widget.trabajador['cod_cosechero'] as String;
    final zona = widget.trabajador['zona'] as int? ?? 1;
    final trabajadorId = widget.trabajador['trabajador_id'] as String;

    GamificationData? data;
    if (token != null) {
      data = await GamificationService.fetchFromServer(cod, token);
    }
    data ??= await GamificationService.calculateLocally(trabajadorId, zona);

    if (mounted) setState(() => _gamData = data);
  }

  Future<void> _syncAndRefresh() async {
    await SyncService.sync();
    await _loadData();
  }

  String get _rol => widget.trabajador['rol'] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    final nombre = widget.trabajador['nombre_completo'] as String;
    final zona = widget.trabajador['zona'] as int? ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Zona $zona  •  ${_rol.toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? AppColors.accent : Colors.white54,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Salir',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          if (_rol == 'cosechador' || _rol == 'recolector')
            CosechaScreen(trabajador: widget.trabajador, onSaved: _loadData)
          else if (_rol == 'fertilizador')
            FertilizacionScreen(trabajador: widget.trabajador, onSaved: _loadData)
          else
            const Center(child: Text('Panel supervisor')),
          GananciasScreen(trabajador: widget.trabajador),
          LeaderboardScreen(
            codCosechero: widget.trabajador['cod_cosechero'] as String,
            gamData: _gamData,
          ),
          SincronizacionScreen(onSync: _syncAndRefresh),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.primary,
        indicatorColor: AppColors.accent,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
            selectedIcon: const Icon(Icons.add_circle, color: Colors.white),
            label: _rol == 'fertilizador' ? 'Fertilización' : 'Cosecha',
          ),
          const NavigationDestination(
            icon: Icon(Icons.attach_money, color: Colors.white70),
            selectedIcon: Icon(Icons.attach_money, color: Colors.white),
            label: 'Ganancias',
          ),
          const NavigationDestination(
            icon: Icon(Icons.leaderboard, color: Colors.white70),
            selectedIcon: Icon(Icons.leaderboard, color: Colors.white),
            label: 'Ranking',
          ),
          const NavigationDestination(
            icon: Icon(Icons.sync, color: Colors.white70),
            selectedIcon: Icon(Icons.sync, color: Colors.white),
            label: 'Sync',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final gam = _gamData;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero earnings card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('Ganancias hoy',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    gam != null ? formatCOP(gam.gananciasHoyCop) : '$ —',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statChip(Icons.grain,
                          '${gam?.racimosHoy ?? 0} racimos', Colors.white),
                      _statChip(Icons.scale,
                          '${gam?.kgHoy.toStringAsFixed(0) ?? 0} kg', Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Days progress toward bono
            if (gam?.proximoBono != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: AppColors.accent, size: 24),
                          const SizedBox(width: 8),
                          const Text('Próximo Bono',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(gam!.proximoBono!['nombre'] as String,
                          style: const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (gam.proximoBono!['progreso'] as num).toDouble() /
                            (gam.proximoBono!['umbral'] as num).toDouble(),
                        backgroundColor: Colors.grey[200],
                        color: AppColors.accent,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(gam.proximoBono!['progreso'] as num).toInt()} / ${(gam.proximoBono!['umbral'] as num).toInt()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatCOP(gam.proximoBono!['monto_cop'] as num),
                            style: const TextStyle(
                                color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Quincena summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Esta quincena',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _summaryRow('Ganancias', formatCOP(gam?.gananciasQuincenaCop ?? 0)),
                    _summaryRow('Racimos', '${gam?.racimosQuincena ?? 0}'),
                    _summaryRow('Días trabajados', '${gam?.diasTrabajadosQuincena ?? 0}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick action button
            if (_rol == 'cosechador' || _rol == 'recolector')
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 28),
                label: const Text('REGISTRAR COSECHA', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => setState(() => _selectedIndex = 1),
              )
            else if (_rol == 'fertilizador')
              ElevatedButton.icon(
                icon: const Icon(Icons.eco, size: 28),
                label: const Text('REGISTRAR FERTILIZACIÓN', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => setState(() => _selectedIndex = 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 18),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      );

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_worker_id');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
