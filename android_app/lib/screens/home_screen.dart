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
    return Scaffold(
      backgroundColor: AppColors.background,
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
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() => Container(
    decoration: BoxDecoration(
      color: AppColors.primary,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, -4))],
    ),
    child: SafeArea(
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            _navItem(0, Icons.home_rounded, 'Inicio'),
            _navItem(1, _rol == 'fertilizador' ? Icons.eco_rounded : Icons.grass_rounded,
                _rol == 'fertilizador' ? 'Ferti' : 'Cosecha'),
            _navItem(2, Icons.payments_rounded, 'Ganancias'),
            _navItem(3, Icons.emoji_events_rounded, 'Ranking'),
            _navItem(4, Icons.sync_rounded, 'Sync'),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: selected ? Colors.white : Colors.white38, size: 26),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(
                color: selected ? AppColors.accent : Colors.white38,
                fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final gam = _gamData;
    final nombre = (widget.trabajador['nombre_completo'] as String).split(' ').first;
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.accent,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildTopBar(nombre)),
          SliverToBoxAdapter(child: _buildEarningsHero(gam)),
          SliverToBoxAdapter(child: _buildStatsRow(gam)),
          if (gam?.proximoBono != null)
            SliverToBoxAdapter(child: _buildBonoCard(gam!)),
          SliverToBoxAdapter(child: _buildQuincenaCard(gam)),
          SliverToBoxAdapter(child: _buildCTAButton()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildTopBar(String nombre) => Container(
    color: AppColors.primary,
    padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¡Hola, $nombre! 👋', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(_rol.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 1)),
            ],
          ),
        ),
        Row(children: [
          Icon(_isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: _isOnline ? AppColors.accent : Colors.white38, size: 22),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _logout,
            child: const Icon(Icons.logout_rounded, color: Colors.white54, size: 22),
          ),
        ]),
      ],
    ),
  );

  Widget _buildEarningsHero(GamificationData? gam) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
    child: Column(
      children: [
        const Text('LO QUE GANASTE HOY', style: TextStyle(color: Colors.white54, fontSize: 13, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(
          gam != null ? formatCOP(gam.gananciasHoyCop) : r'$ —',
          style: const TextStyle(color: AppColors.accent, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const SizedBox(height: 4),
        Text('Esta quincena: ${gam != null ? formatCOP(gam.gananciasQuincenaCop) : "$ —"}',
            style: const TextStyle(color: Colors.white60, fontSize: 16)),
      ],
    ),
  );

  Widget _buildStatsRow(GamificationData? gam) => Container(
    color: AppColors.primary,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    child: Row(
      children: [
        _statPill(Icons.grain_rounded, '${gam?.racimosHoy ?? 0}', 'racimos hoy'),
        const SizedBox(width: 12),
        _statPill(Icons.scale_rounded, '${gam?.kgHoy.toStringAsFixed(0) ?? 0}', 'kg hoy'),
      ],
    ),
  );

  Widget _statPill(IconData icon, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildBonoCard(GamificationData gam) {
    final bono = gam.proximoBono!;
    final progreso = (bono['progreso'] as num).toDouble();
    final umbral = (bono['umbral'] as num).toDouble();
    final pct = (progreso / umbral).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(bono['nombre'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary))),
          ]),
          const SizedBox(height: 12),
          Stack(children: [
            Container(height: 18, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(9))),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(height: 18, decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentDark]),
                borderRadius: BorderRadius.circular(9),
              )),
            ),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${progreso.toInt()} de ${umbral.toInt()} días',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            Text(formatCOP(bono['monto_cop'] as num),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
          ]),
        ],
      ),
    );
  }

  Widget _buildQuincenaCard(GamificationData? gam) => Container(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Text('📅', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text('Esta quincena', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.primary)),
        ]),
        const SizedBox(height: 16),
        _qRow('💰', 'Ganancias', formatCOP(gam?.gananciasQuincenaCop ?? 0), isMain: true),
        const Divider(height: 20),
        _qRow('🌿', 'Racimos cosechados', '${gam?.racimosQuincena ?? 0}'),
        const SizedBox(height: 8),
        _qRow('📆', 'Días trabajados', '${gam?.diasTrabajadosQuincena ?? 0}'),
      ],
    ),
  );

  Widget _qRow(String emoji, String label, String value, {bool isMain = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          fontSize: isMain ? 16 : 15,
          color: isMain ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isMain ? FontWeight.w600 : FontWeight.normal,
        )),
      ]),
      Text(value, style: TextStyle(
        fontSize: isMain ? 20 : 16,
        fontWeight: FontWeight.bold,
        color: isMain ? AppColors.success : AppColors.primary,
      )),
    ],
  );

  Widget _buildCTAButton() {
    if (_rol != 'cosechador' && _rol != 'recolector' && _rol != 'fertilizador') return const SizedBox();
    final isFertil = _rol == 'fertilizador';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 1),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentDark]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isFertil ? Icons.eco_rounded : Icons.grass_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                isFertil ? 'REGISTRAR FERTILIZACIÓN' : 'REGISTRAR COSECHA',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
