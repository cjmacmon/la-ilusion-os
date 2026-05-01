import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'hacienda_la_ilusion.db'),
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trabajador_local (
        trabajador_id   TEXT PRIMARY KEY,
        cod_cosechero   TEXT UNIQUE NOT NULL,
        cedula          TEXT NOT NULL,
        nombre_completo TEXT NOT NULL,
        telefono        TEXT,
        pin             TEXT NOT NULL,
        rol             TEXT NOT NULL,
        zona            INTEGER,
        activo          INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE lote_local (
        lote_id          INTEGER PRIMARY KEY,
        cod_lote         TEXT UNIQUE NOT NULL,
        nombre           TEXT NOT NULL,
        zona             INTEGER NOT NULL,
        hectareas        REAL,
        numero_palmas    INTEGER,
        peso_promedio_kg REAL,
        anio_siembra     INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cosecha_local (
        cosecha_id                     TEXT PRIMARY KEY,
        trabajador_id                  TEXT NOT NULL,
        cod_cosechero                  TEXT NOT NULL,
        lote_id                        INTEGER NOT NULL,
        ticket_extractora              TEXT,
        fecha_corte                    TEXT NOT NULL,
        tipo_cosecha                   TEXT NOT NULL,
        metodo_recoleccion             TEXT NOT NULL DEFAULT 'NO_APLICA',
        total_racimos                  INTEGER NOT NULL DEFAULT 0,
        peso_extractora_sin_recolector REAL NOT NULL DEFAULT 0,
        total_racimos_recolector       INTEGER,
        peso_extractora_recolector     REAL,
        observaciones                  TEXT,
        sync_status                    TEXT NOT NULL DEFAULT 'pending',
        created_offline                INTEGER NOT NULL DEFAULT 1,
        device_id                      TEXT,
        fecha_creacion                 TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fertilizacion_local (
        fertilizacion_id    TEXT PRIMARY KEY,
        trabajador_id       TEXT NOT NULL,
        lote_id             INTEGER NOT NULL,
        fecha               TEXT NOT NULL,
        palmas_fertilizadas INTEGER NOT NULL DEFAULT 0,
        dosis_por_palma     REAL NOT NULL DEFAULT 0,
        total_aplicado      REAL NOT NULL DEFAULT 0,
        observaciones       TEXT,
        sync_status         TEXT NOT NULL DEFAULT 'pending',
        device_id           TEXT,
        fecha_creacion      TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tarifa_local (
        tarifa_id         INTEGER PRIMARY KEY,
        tipo_labor        TEXT NOT NULL,
        zona              INTEGER,
        precio_por_kg     REAL,
        precio_por_unidad REAL,
        fecha_inicio      TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incentivo_local (
        incentivo_id INTEGER PRIMARY KEY,
        nombre       TEXT NOT NULL,
        tipo         TEXT NOT NULL,
        umbral       REAL NOT NULL,
        monto_bono   REAL NOT NULL,
        activo       INTEGER NOT NULL DEFAULT 1,
        descripcion  TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ausencia_local (
        ausencia_id   TEXT PRIMARY KEY,
        trabajador_id TEXT NOT NULL,
        fecha         TEXT NOT NULL,
        justificada   INTEGER NOT NULL DEFAULT 0,
        motivo        TEXT,
        registrado_por TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_cosecha_sync ON cosecha_local(sync_status)');
    await db.execute('CREATE INDEX idx_cosecha_fecha ON cosecha_local(fecha_corte)');
    await db.execute('CREATE INDEX idx_fert_sync ON fertilizacion_local(sync_status)');
  }

  // ── TRABAJADORES ────────────────────────────────────────
  static Future<void> upsertTrabajador(Map<String, dynamic> m) async {
    final database = await db;
    await database.insert('trabajador_local', m, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getTrabajadorByCod(String cod) async {
    final database = await db;
    final rows = await database.query('trabajador_local', where: 'cod_cosechero = ?', whereArgs: [cod]);
    return rows.isEmpty ? null : rows.first;
  }

  // ── LOTES ───────────────────────────────────────────────
  static Future<void> upsertLote(Map<String, dynamic> m) async {
    final database = await db;
    await database.insert('lote_local', m, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getLotesByZona(int zona) async {
    final database = await db;
    return database.query('lote_local', where: 'zona = ?', whereArgs: [zona], orderBy: 'nombre');
  }

  static Future<List<Map<String, dynamic>>> getAllLotes() async {
    final database = await db;
    return database.query('lote_local', orderBy: 'zona, nombre');
  }

  // ── COSECHA ─────────────────────────────────────────────
  static Future<void> insertCosecha(Map<String, dynamic> m) async {
    final database = await db;
    await database.insert('cosecha_local', m, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPendingCosechas() async {
    final database = await db;
    return database.query('cosecha_local', where: "sync_status = 'pending'");
  }

  static Future<void> markCosechaSynced(String cosechaId) async {
    final database = await db;
    await database.update('cosecha_local', {'sync_status': 'synced'},
        where: 'cosecha_id = ?', whereArgs: [cosechaId]);
  }

  static Future<List<Map<String, dynamic>>> getCosechasByWorkerAndDate(
      String trabajadorId, String fechaInicio, String fechaFin) async {
    final database = await db;
    return database.query(
      'cosecha_local',
      where: 'trabajador_id = ? AND fecha_corte >= ? AND fecha_corte <= ?',
      whereArgs: [trabajadorId, fechaInicio, fechaFin],
      orderBy: 'fecha_corte DESC',
    );
  }

  static Future<int> getPendingCosechaCount() async {
    final database = await db;
    final result = await database.rawQuery(
      "SELECT COUNT(*) as cnt FROM cosecha_local WHERE sync_status = 'pending'",
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── FERTILIZACION ────────────────────────────────────────
  static Future<void> insertFertilizacion(Map<String, dynamic> m) async {
    final database = await db;
    await database.insert('fertilizacion_local', m, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getPendingFertilizaciones() async {
    final database = await db;
    return database.query('fertilizacion_local', where: "sync_status = 'pending'");
  }

  static Future<void> markFertilizacionSynced(String id) async {
    final database = await db;
    await database.update('fertilizacion_local', {'sync_status': 'synced'},
        where: 'fertilizacion_id = ?', whereArgs: [id]);
  }

  static Future<int> getPendingFertilizacionCount() async {
    final database = await db;
    final result = await database.rawQuery(
      "SELECT COUNT(*) as cnt FROM fertilizacion_local WHERE sync_status = 'pending'",
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── TARIFAS ─────────────────────────────────────────────
  static Future<void> upsertTarifa(Map<String, dynamic> m) async {
    final database = await db;
    await database.insert('tarifa_local', m, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getTarifasByZona(int zona) async {
    final database = await db;
    return database.query('tarifa_local',
        where: 'zona = ? OR zona IS NULL', whereArgs: [zona]);
  }

  // ── INCENTIVOS ───────────────────────────────────────────
  static Future<void> upsertIncentivo(Map<String, dynamic> m) async {
    final database = await db;
    await database.insert('incentivo_local', m, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getActiveIncentivos() async {
    final database = await db;
    return database.query('incentivo_local', where: 'activo = 1');
  }

  // ── AUSENCIAS ───────────────────────────────────────────
  static Future<void> insertAusencia(Map<String, dynamic> m) async {
    final database = await db;
    await database.insert('ausencia_local', m, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
