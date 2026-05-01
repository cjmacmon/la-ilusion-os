class Incentivo {
  final int incentivoId;
  final String nombre;
  final String tipo;
  final double umbral;
  final double montoBono;
  final bool activo;
  final String? descripcion;

  const Incentivo({
    required this.incentivoId,
    required this.nombre,
    required this.tipo,
    required this.umbral,
    required this.montoBono,
    required this.activo,
    this.descripcion,
  });

  factory Incentivo.fromMap(Map<String, dynamic> m) => Incentivo(
        incentivoId: m['incentivo_id'] as int,
        nombre: m['nombre'] as String,
        tipo: m['tipo'] as String,
        umbral: (m['umbral'] as num).toDouble(),
        montoBono: (m['monto_bono'] as num).toDouble(),
        activo: (m['activo'] as int? ?? 1) == 1,
        descripcion: m['descripcion'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'incentivo_id': incentivoId,
        'nombre': nombre,
        'tipo': tipo,
        'umbral': umbral,
        'monto_bono': montoBono,
        'activo': activo ? 1 : 0,
        'descripcion': descripcion,
      };
}
