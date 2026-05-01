import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'db/local_database.dart';
import 'services/sync_service.dart';
import 'services/connectivity_service.dart';
import 'services/seed_service.dart';

const taskSyncBackground = 'hacienda_sync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == taskSyncBackground) {
      final online = await ConnectivityService.isOnline();
      if (online) await SyncService.sync();
    }
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Register background sync every 15 minutes
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    taskSyncBackground,
    taskSyncBackground,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  runApp(const HaciendaApp());
}

class HaciendaApp extends StatelessWidget {
  const HaciendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hacienda La Ilusión',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'CO')],
      home: const _StartupRouter(),
    );
  }
}

class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Ensure DB is initialized
    await LocalDatabase.db;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final workerId = prefs.getString('current_worker_id');
    final workerCod = prefs.getString('current_worker_cod');

    // Try to seed from server on first run
    if (token != null && await SeedService.needsSeed()) {
      await SeedService.seedFromServer(token);
    }

    if (!mounted) return;

    if (token != null && workerId != null) {
      // Auto-login: restore session
      final trabajadorRow = await LocalDatabase.getTrabajadorByCod(workerCod ?? '');
      if (trabajadorRow != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(trabajador: trabajadorRow)),
        );
        return;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.agriculture, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hacienda La Ilusión',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
