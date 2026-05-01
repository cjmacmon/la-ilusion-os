class Fertilizacion {
  final String fertilizacionId;
  final String trabajadorId;
  final int loteId;
  final String fecha;
  final int palmasFertilizadas;
  final double dosisPorPalma;
  final double totalAplicado;
  final String? observaciones;
  final String syncStatus;
  final String? deviceId;

  const Fertilizacion({
    required this.fertilizacionId,
    required this.trabajadorId,
    required this.loteId,
    required this.fecha,
    required this.palmasFertilizadas,
    required this.dosisPorPalma,
    required this.totalAplicado,
    this.observaciones,
    this.syncStatus = 'pending',
    this.deviceId,
  });

  factory Fertilizacion.fromMap(Map<String, dynamic> m) => Fertilizacion(
        fertilizacionId: m['fertilizacion_id'] as String,
        trabajadorId: m['trabajador_id'] as String,
        loteId: m['lote_id'] as int,
        fecha: m['fecha'] as String,
        palmasFertilizadas: m['palmas_fertilizadas'] as int? ?? 0,
        dosisPorPalma: (m['dosis_por_palma'] as num?)?.toDouble() ?? 0,
        totalAplicado: (m['total_aplicado'] as num?)?.toDouble() ?? 0,
        observaciones: m['observaciones'] as String?,
        syncStatus: m['sync_status'] as String? ?? 'pending',
        deviceId: m['device_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'fertilizacion_id': fertilizacionId,
        'trabajador_id': trabajadorId,
        'lote_id': loteId,
        'fecha': fecha,
        'palmas_fertilizadas': palmasFertilizadas,
        'dosis_por_palma': dosisPorPalma,
        'total_aplicado': totalAplicado,
        'observaciones': observaciones,
        'sync_status': syncStatus,
        'device_id': deviceId,
      };

  Map<String, dynamic> toJson() => {
        'fertilizacion_id': fertilizacionId,
        'trabajador_id': trabajadorId,
        'lote_id': loteId,
        'fecha': fecha,
        'palmas_fertilizadas': palmasFertilizadas,
        'dosis_por_palma': dosisPorPalma,
        'total_aplicado': totalAplicado,
        'observaciones': observaciones,
        'device_id': deviceId,
      };
}
