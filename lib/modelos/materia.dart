import 'estudiante.dart';

/// Materia que un estudiante tiene inscrita.
///
/// Cada instancia representa la inscripcion concreta de UN estudiante a UNA
/// materia, por eso guarda tanto los datos de la materia como el estudiante
/// dueno de esa inscripcion y la fecha en que se registro.
class Materia {
  /// Codigo de la materia (ej. SI-220). Nunca cambia despues de crearla.
  final String codigoMateria;

  /// Momento en que el estudiante inscribio la materia.
  final DateTime fechaRegistro;

  /// Estudiante que inscribio esta materia.
  final Estudiante estudiante;

  /// Nombre largo de la materia.
  final String nombreMateria;

  /// Constructor con parametros nombrados y requeridos.
  Materia({
    required this.codigoMateria,
    required this.fechaRegistro,
    required this.estudiante,
    required this.nombreMateria,
  });

  /// Constructor factoria: arma una [Materia] desde un `Map<String, dynamic>`.
  ///
  /// El estudiante puede venir dentro del propio mapa (clave `estudiante`) o
  /// llegar por el parametro [estudiante], que es lo que ocurre cuando quien
  /// deserializa es [Estudiante.fromJson] y ya tiene la instancia en la mano.
  factory Materia.fromJson(
    Map<String, dynamic> json, {
    Estudiante? estudiante,
  }) {
    final Estudiante dueno = estudiante ??
        Estudiante.fromJson(json['estudiante'] as Map<String, dynamic>);

    return Materia(
      codigoMateria: json['codigoMateria'] as String,
      fechaRegistro: DateTime.parse(json['fechaRegistro'] as String),
      estudiante: dueno,
      nombreMateria: json['nombreMateria'] as String,
    );
  }

  /// Convierte la materia a un `Map<String, dynamic>` listo para `jsonEncode`.
  ///
  /// [incluirEstudiante] existe para cortar la recursion: un estudiante tiene
  /// materias y cada materia tiene un estudiante, asi que al serializar desde
  /// el estudiante se omite el dato repetido.
  Map<String, dynamic> toJson({bool incluirEstudiante = true}) {
    return <String, dynamic>{
      'codigoMateria': codigoMateria,
      'nombreMateria': nombreMateria,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      if (incluirEstudiante)
        'estudiante': estudiante.toJson(incluirMaterias: false),
    };
  }

  @override
  String toString() =>
      '$codigoMateria - $nombreMateria (inscrita el ${_soloFecha(fechaRegistro)})';

  static String _soloFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';
}

/// Materia del catalogo de la carrera, todavia sin estudiante asignado.
///
/// Solo tiene datos inmutables, por eso puede tener un constructor `const` y
/// vivir en una lista `const` que se arma en tiempo de compilacion.
class MateriaDisponible {
  final String codigo;
  final String nombre;

  const MateriaDisponible({required this.codigo, required this.nombre});

  @override
  String toString() => '$codigo - $nombre';
}

/// Catalogo fijo de materias que se pueden inscribir.
const List<MateriaDisponible> catalogoMaterias = <MateriaDisponible>[
  MateriaDisponible(codigo: 'SI-220', nombre: 'Fundamentos de Programacion'),
  MateriaDisponible(codigo: 'SI-221', nombre: 'Programacion I'),
  MateriaDisponible(codigo: 'SI-310', nombre: 'Estructuras de Datos'),
  MateriaDisponible(codigo: 'SI-330', nombre: 'Base de Datos I'),
  MateriaDisponible(codigo: 'MAT-101', nombre: 'Calculo I'),
  MateriaDisponible(codigo: 'MAT-207', nombre: 'Matematica Discreta'),
];
