import 'materia.dart';

/// Estudiante del sistema. Puede tener varias materias inscritas.
class Estudiante {
  /// Numero de registro universitario. Es la identidad del estudiante.
  final String registro;

  final DateTime fechaNacimiento;
  final String nombre;
  final String apellido;

  /// Lista privada y mutable de materias. La lista en si es `final` (siempre
  /// es la misma lista), lo que cambia es su contenido.
  final List<Materia> _materias = <Materia>[];

  /// `late final` con inicializador: el texto se arma la primera vez que
  /// alguien lo pide y desde ahi queda guardado.
  late final String nombreCompleto = '$nombre $apellido';

  /// Constructor con parametros nombrados y requeridos.
  Estudiante({
    required this.registro,
    required this.fechaNacimiento,
    required this.nombre,
    required this.apellido,
  });

  /// Vista de solo lectura de las materias: nadie de afuera puede agregar
  /// materias saltandose [inscribirMateria].
  List<Materia> get materias => List<Materia>.unmodifiable(_materias);

  int get cantidadMaterias => _materias.length;

  /// Edad en anios cumplidos al dia de hoy.
  int get edad {
    final DateTime hoy = DateTime.now();
    int anios = hoy.year - fechaNacimiento.year;
    final bool aunNoCumple = hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day);
    if (aunNoCumple) anios--;
    return anios;
  }

  bool tieneMateria(String codigoMateria) => _materias.any((Materia m) =>
      m.codigoMateria.toUpperCase() == codigoMateria.toUpperCase());

  /// Agrega una materia validando que sea de este estudiante y que no este
  /// inscrita dos veces.
  void inscribirMateria(Materia materia) {
    if (materia.estudiante.registro != registro) {
      throw ArgumentError(
        'La materia ${materia.codigoMateria} pertenece al registro '
        '${materia.estudiante.registro}, no a $registro.',
      );
    }
    if (tieneMateria(materia.codigoMateria)) {
      throw StateError(
        'El estudiante $registro ya tiene inscrita la materia '
        '${materia.codigoMateria}.',
      );
    }
    _materias.add(materia);
  }

  /// Quita una materia. Devuelve `true` si estaba inscrita.
  bool darDeBajaMateria(String codigoMateria) {
    final int antes = _materias.length;
    _materias.removeWhere((Materia m) =>
        m.codigoMateria.toUpperCase() == codigoMateria.toUpperCase());
    return _materias.length < antes;
  }

  /// Constructor factoria: arma un [Estudiante] (con sus materias) desde un
  /// `Map<String, dynamic>`.
  factory Estudiante.fromJson(Map<String, dynamic> json) {
    final Estudiante estudiante = Estudiante(
      registro: json['registro'] as String,
      fechaNacimiento: DateTime.parse(json['fechaNacimiento'] as String),
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
    );

    final List<dynamic> materiasJson =
        (json['materias'] as List<dynamic>?) ?? const <dynamic>[];

    for (final dynamic item in materiasJson) {
      estudiante._materias.add(
        // Se pasa el estudiante ya creado para no volver a deserializarlo.
        Materia.fromJson(item as Map<String, dynamic>, estudiante: estudiante),
      );
    }

    return estudiante;
  }

  /// Convierte el estudiante a un `Map<String, dynamic>`.
  Map<String, dynamic> toJson({bool incluirMaterias = true}) {
    return <String, dynamic>{
      'registro': registro,
      'nombre': nombre,
      'apellido': apellido,
      'fechaNacimiento': fechaNacimiento.toIso8601String(),
      if (incluirMaterias)
        'materias': _materias
            .map((Materia m) => m.toJson(incluirEstudiante: false))
            .toList(),
    };
  }

  @override
  String toString() =>
      '[$registro] $nombreCompleto - $edad años - $cantidadMaterias materia(s)';
}
