import 'dart:convert';
import 'dart:io';

import '../modelos/estudiante.dart';
import '../modelos/materia.dart';

/// Guarda los estudiantes en memoria y los persiste en un archivo JSON.
class RegistroServicio {
  /// Ruta por defecto del archivo de datos.
  static const String rutaPorDefecto = 'datos/estudiantes.json';

  /// `late final`: el archivo se decide en el cuerpo del constructor y despues
  /// ya no se puede reasignar.
  late final File _archivo;

  /// Registro del estudiante -> estudiante.
  final Map<String, Estudiante> _estudiantes = <String, Estudiante>{};

  RegistroServicio({String? ruta}) {
    _archivo = File(ruta ?? rutaPorDefecto);
  }

  List<Estudiante> get estudiantes {
    final List<Estudiante> lista = _estudiantes.values.toList();
    lista
        .sort((Estudiante a, Estudiante b) => a.registro.compareTo(b.registro));
    return List<Estudiante>.unmodifiable(lista);
  }

  bool get vacio => _estudiantes.isEmpty;

  Estudiante? buscar(String registro) => _estudiantes[registro.trim()];

  /// Registra un estudiante nuevo. Falla si el registro ya existe.
  Estudiante registrarEstudiante({
    required String registro,
    required DateTime fechaNacimiento,
    required String nombre,
    required String apellido,
  }) {
    final String clave = registro.trim();
    if (_estudiantes.containsKey(clave)) {
      throw StateError('Ya existe un estudiante con el registro $clave.');
    }

    final Estudiante estudiante = Estudiante(
      registro: clave,
      fechaNacimiento: fechaNacimiento,
      nombre: nombre.trim(),
      apellido: apellido.trim(),
    );

    _estudiantes[clave] = estudiante;
    return estudiante;
  }

  /// Inscribe una materia a un estudiante ya registrado.
  Materia inscribirMateria({
    required String registro,
    required String codigoMateria,
    required String nombreMateria,
    DateTime? fechaRegistro,
  }) {
    final Estudiante? estudiante = buscar(registro);
    if (estudiante == null) {
      throw StateError('No existe un estudiante con el registro $registro.');
    }

    final Materia materia = Materia(
      codigoMateria: codigoMateria.trim().toUpperCase(),
      fechaRegistro: fechaRegistro ?? DateTime.now(),
      estudiante: estudiante,
      nombreMateria: nombreMateria.trim(),
    );

    estudiante.inscribirMateria(materia);
    return materia;
  }

  bool darDeBajaMateria(
      {required String registro, required String codigoMateria}) {
    final Estudiante? estudiante = buscar(registro);
    if (estudiante == null) {
      throw StateError('No existe un estudiante con el registro $registro.');
    }
    return estudiante.darDeBajaMateria(codigoMateria);
  }

  /// Todas las materias inscritas por todos los estudiantes.
  List<Materia> todasLasMaterias() => <Materia>[
        for (final Estudiante e in estudiantes) ...e.materias,
      ];

  // --------------------------------------------------------------------
  // Serializacion / deserializacion
  // --------------------------------------------------------------------

  /// Representacion JSON de todo el registro.
  String aJson({bool identado = true}) {
    final List<Map<String, dynamic>> datos =
        estudiantes.map((Estudiante e) => e.toJson()).toList();
    if (!identado) return jsonEncode(datos);
    return const JsonEncoder.withIndent('  ').convert(datos);
  }

  /// Carga estudiantes desde una cadena JSON (reemplaza lo que haya en memoria).
  int cargarDesdeJson(String contenido) {
    final dynamic decodificado = jsonDecode(contenido);
    if (decodificado is! List) {
      throw const FormatException('El JSON debe ser una lista de estudiantes.');
    }

    _estudiantes.clear();
    for (final dynamic item in decodificado) {
      final Estudiante estudiante =
          Estudiante.fromJson(item as Map<String, dynamic>);
      _estudiantes[estudiante.registro] = estudiante;
    }
    return _estudiantes.length;
  }

  /// Escribe el registro en el archivo de datos.
  Future<File> guardar() async {
    await _archivo.parent.create(recursive: true);
    return _archivo.writeAsString(aJson());
  }

  /// Lee el archivo de datos. Devuelve cuantos estudiantes cargo (0 si no hay
  /// archivo todavia).
  Future<int> cargar() async {
    if (!await _archivo.exists()) return 0;
    final String contenido = (await _archivo.readAsString()).trim();
    if (contenido.isEmpty) return 0;
    return cargarDesdeJson(contenido);
  }

  String get rutaArchivo => _archivo.path;

  /// Datos de ejemplo para probar el sistema sin cargar todo a mano.
  void cargarDatosDeEjemplo() {
    registrarEstudiante(
      registro: '223001',
      fechaNacimiento: DateTime(2004, 3, 15),
      nombre: 'Ana',
      apellido: 'Quiroga',
    );
    registrarEstudiante(
      registro: '223002',
      fechaNacimiento: DateTime(2003, 11, 2),
      nombre: 'Luis',
      apellido: 'Mendoza',
    );

    inscribirMateria(
      registro: '223001',
      codigoMateria: 'SI-220',
      nombreMateria: 'Fundamentos de Programación',
      fechaRegistro: DateTime(2026, 2, 10),
    );
    inscribirMateria(
      registro: '223001',
      codigoMateria: 'MAT-101',
      nombreMateria: 'Cálculo I',
      fechaRegistro: DateTime(2026, 2, 10),
    );
    inscribirMateria(
      registro: '223002',
      codigoMateria: 'SI-330',
      nombreMateria: 'Base de Datos I',
      fechaRegistro: DateTime(2026, 2, 12),
    );
  }
}
