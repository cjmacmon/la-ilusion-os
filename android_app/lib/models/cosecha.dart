class Cosecha {
  final String cosechaId;
  final String trabajadorId;
  final String codCosechero;
  final int loteId;
  final String? ticketExtractora;
  final String fechaCorte;
  final String tipoCosecha;
  final String metodoRecoleccion;
  final int totalRacimos;
  final double pesoExtractoraSinRecolector;
  final int? totalRacimosRecolector;
  final double? pesoExtractoraRecolector;
  final String? observaciones;
  final String syncStatus;
  final bool createdOffline;
  final String? deviceId;

  const Cosecha({
    required this.cosechaId,
    required this.trabajadorId,
    required this.codCosechero,
    required this.loteId,
    this.ticketExtractora,
    required this.fechaCorte,
    required this.tipoCosecha,
    this.metodoRecoleccion = 'NO_APLICA',
    required this.totalRacimos,
    required this.pesoExtractoraSinRecolector,
    this.totalRacimosRecolector,
    this.pesoExtractoraRecolector,
    this.observaciones,
    this.syncStatus = 'pending',
    this.createdOffline = true,
    this.deviceId,
  });

  factory Cosecha.fromMap(Map<String, dynamic> m) => Cosecha(
        cosechaId: m['cosecha_id'] as String,
        trabajadorId: m['trabajador_id'] as String,
        codCosechero: m['cod_cosechero'] as String,
        loteId: m['lote_id'] as int,
        ticketExtractora: m['ticket_extractora'] as String?,
        fechaCorte: m['fecha_corte'] as String,
        tipoCosecha: m['tipo_cosecha'] as String,
        metodoRecoleccion: m['metodo_recoleccion'] as String? ?? 'NO_APLICA',
        totalRacimos: m['total_racimos'] as int? ?? 0,
        pesoExtractoraSinRecolector: (m['peso_extractora_sin_recolector'] as num?)?.toDouble() ?? 0,
        totalRacimosRecolector: m['total_racimos_recolector'] as int?,
        pesoExtractoraRecolector: (m['peso_extractora_recolector'] as num?)?.toDouble(),
        observaciones: m['observaciones'] as String?,
        syncStatus: m['sync_status'] as String? ?? 'pending',
        createdOffline: (m['created_offline'] as int? ?? 1) == 1,
        deviceId: m['device_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'cosecha_id': cosechaId,
        'trabajador_id': trabajadorId,
        'cod_cosechero': codCosechero,
        'lote_id': loteId,
        'ticket_extractora': ticketExtractora,
        'fecha_corte': fechaCorte,
        'tipo_cosecha': tipoCosecha,
        'metodo_recoleccion': metodoRecoleccion,
        'total_racimos': totalRacimos,
        'peso_extractora_sin_recolector': pesoExtractoraSinRecolector,
        'total_racimos_recolector': totalRacimosRecolector,
        'peso_extractora_recolector': pesoExtractoraRecolector,
        'observaciones': observaciones,
        'sync_status': syncStatus,
        'created_offline': createdOffline ? 1 : 0,
        'device_id': deviceId,
      };

  Map<String, dynamic> toJson() => {
        'cosecha_id': cosechaId,
        'trabajador_id': trabajadorId,
        'cod_cosechero': codCosechero,
        'lote_id': loteId,
        'ticket_extractora': ticketExtractora,
        'fecha_corte': fechaCorte,
        'tipo_cosecha': tipoCosecha,
        'metodo_recoleccion': metodoRecoleccion,
        'total_racimos': totalRacimos,
        'peso_extractora_sin_recolector': pesoExtractoraSinRecolector,
        'total_racimos_recolector': totalRacimosRecolector,
        'peso_extractora_recolector': pesoExtractoraRecolector,
        'observaciones': observaciones,
        'created_offline': createdOffline,
        'device_id': deviceId,
      };
}
