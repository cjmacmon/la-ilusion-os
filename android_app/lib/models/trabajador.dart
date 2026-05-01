class Trabajador {
  final String trabajadorId;
  final String codCosechero;
  final String cedula;
  final String nombreCompleto;
  final String? telefono;
  final String pin;
  final String rol;
  final int? zona;
  final bool activo;

  const Trabajador({
    required this.trabajadorId,
    required this.codCosechero,
    required this.cedula,
    required this.nombreCompleto,
    this.telefono,
    required this.pin,
    required this.rol,
    this.zona,
    required this.activo,
  });

  factory Trabajador.fromMap(Map<String, dynamic> m) => Trabajador(
        trabajadorId: m['trabajador_id'] as String,
        codCosechero: m['cod_cosechero'] as String,
        cedula: m['cedula'] as String,
        nombreCompleto: m['nombre_completo'] as String,
        telefono: m['telefono'] as String?,
        pin: m['pin'] as String,
        rol: m['rol'] as String,
        zona: m['zona'] as int?,
        activo: (m['activo'] as int? ?? 1) == 1,
      );

  Map<String, dynamic> toMap() => {
        'trabajador_id': trabajadorId,
        'cod_cosechero': codCosechero,
        'cedula': cedula,
        'nombre_completo': nombreCompleto,
        'telefono': telefono,
        'pin': pin,
        'rol': rol,
        'zona': zona,
        'activo': activo ? 1 : 0,
      };

  bool get esCosechadorORecolector => rol == 'cosechador' || rol == 'recolector';
  bool get esFertilizador => rol == 'fertilizador';
  bool get esSupervisor => rol == 'supervisor';
  bool get esAdmin => rol == 'admin';
}
