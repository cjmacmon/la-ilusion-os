class Lote {
  final int loteId;
  final String codLote;
  final String nombre;
  final int zona;
  final double? hectareas;
  final int? numeroPalmas;
  final double? pesoPromedioKg;
  final int? anioSiembra;

  const Lote({
    required this.loteId,
    required this.codLote,
    required this.nombre,
    required this.zona,
    this.hectareas,
    this.numeroPalmas,
    this.pesoPromedioKg,
    this.anioSiembra,
  });

  factory Lote.fromMap(Map<String, dynamic> m) => Lote(
        loteId: m['lote_id'] as int,
        codLote: m['cod_lote'] as String,
        nombre: m['nombre'] as String,
        zona: m['zona'] as int,
        hectareas: (m['hectareas'] as num?)?.toDouble(),
        numeroPalmas: m['numero_palmas'] as int?,
        pesoPromedioKg: (m['peso_promedio_kg'] as num?)?.toDouble(),
        anioSiembra: m['anio_siembra'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'lote_id': loteId,
        'cod_lote': codLote,
        'nombre': nombre,
        'zona': zona,
        'hectareas': hectareas,
        'numero_palmas': numeroPalmas,
        'peso_promedio_kg': pesoPromedioKg,
        'anio_siembra': anioSiembra,
      };

  String get displayName => '$nombre (Zona $zona)';
}
