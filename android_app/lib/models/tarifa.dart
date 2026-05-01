class Tarifa {
  final int tarifaId;
  final String tipoLabor;
  final int? zona;
  final double? precioPorKg;
  final double? precioPorUnidad;
  final String fechaInicio;

  const Tarifa({
    required this.tarifaId,
    required this.tipoLabor,
    this.zona,
    this.precioPorKg,
    this.precioPorUnidad,
    required this.fechaInicio,
  });

  factory Tarifa.fromMap(Map<String, dynamic> m) => Tarifa(
        tarifaId: m['tarifa_id'] as int,
        tipoLabor: m['tipo_labor'] as String,
        zona: m['zona'] as int?,
        precioPorKg: (m['precio_por_kg'] as num?)?.toDouble(),
        precioPorUnidad: (m['precio_por_unidad'] as num?)?.toDouble(),
        fechaInicio: m['fecha_inicio'] as String,
      );

  Map<String, dynamic> toMap() => {
        'tarifa_id': tarifaId,
        'tipo_labor': tipoLabor,
        'zona': zona,
        'precio_por_kg': precioPorKg,
        'precio_por_unidad': precioPorUnidad,
        'fecha_inicio': fechaInicio,
      };
}
