import 'dart:io';

import '../modelos/estudiante.dart';
import '../modelos/materia.dart';
import '../servicios/registro_servicio.dart';

/// Menu de consola del sistema de registro.
class Menu {
  static const String _separador =
      '------------------------------------------------------------';

  final RegistroServicio servicio;

  /// `late final`: se asigna una sola vez, cuando arranca [ejecutar].
  late final DateTime _inicioSesion;

  Menu({RegistroServicio? servicio})
      : servicio = servicio ?? RegistroServicio();

  Future<void> ejecutar() async {
    _inicioSesion = DateTime.now();

    final int cargados = await servicio.cargar();
    print(_separador);
    print('   SISTEMA DE REGISTRO DE ESTUDIANTES');
    print('   Sesion iniciada: ${_fechaHora(_inicioSesion)}');
    if (cargados > 0) {
      print(
          '   Se cargaron $cargados estudiante(s) de ${servicio.rutaArchivo}');
    }
    print(_separador);

    bool salir = false;
    while (!salir) {
      _mostrarOpciones();
      final String? opcion = _leer('Opcion');

      // Entrada cerrada (Ctrl+D o script con datos por tuberia): se termina.
      if (opcion == null) {
        print('\nEntrada cerrada. Saliendo...');
        break;
      }

      try {
        switch (opcion.trim()) {
          case '1':
            _registrarEstudiante();
          case '2':
            _listarEstudiantes();
          case '3':
            _inscribirMateria();
          case '4':
            _verMateriasDeEstudiante();
          case '5':
            _darDeBajaMateria();
          case '6':
            _verJson();
          case '7':
            await _guardar();
          case '8':
            _cargarEjemplo();
          case '0':
            salir = true;
          case '':
            break;
          default:
            print('Opcion no valida.');
        }
      } on StateError catch (e) {
        print('ERROR: ${e.message}');
      } on ArgumentError catch (e) {
        print('ERROR: ${e.message}');
      } on FormatException catch (e) {
        print('ERROR de formato: ${e.message}');
      }
    }

    if (salir) {
      await servicio.guardar();
      print('Datos guardados en ${servicio.rutaArchivo}. Hasta luego.');
    }
  }

  void _mostrarOpciones() {
    print('\n$_separador');
    print(' 1. Registrar estudiante');
    print(' 2. Listar estudiantes');
    print(' 3. Inscribir materia a un estudiante');
    print(' 4. Ver materias de un estudiante');
    print(' 5. Dar de baja una materia');
    print(' 6. Ver los datos en JSON (serializar)');
    print(' 7. Guardar en archivo');
    print(' 8. Cargar datos de ejemplo');
    print(' 0. Salir');
    print(_separador);
  }

  // --------------------------------------------------------------------
  // Opciones
  // --------------------------------------------------------------------

  void _registrarEstudiante() {
    final String? registro = _leerObligatorio('Numero de registro');
    if (registro == null) return;

    final String? nombre = _leerObligatorio('Nombre');
    if (nombre == null) return;

    final String? apellido = _leerObligatorio('Apellido');
    if (apellido == null) return;

    final DateTime? nacimiento = _leerFecha('Fecha de nacimiento (dd/mm/aaaa)');
    if (nacimiento == null) return;

    final Estudiante estudiante = servicio.registrarEstudiante(
      registro: registro,
      fechaNacimiento: nacimiento,
      nombre: nombre,
      apellido: apellido,
    );

    print('Estudiante registrado: $estudiante');
  }

  void _listarEstudiantes() {
    if (servicio.vacio) {
      print('Todavia no hay estudiantes registrados.');
      return;
    }

    print('\nESTUDIANTES REGISTRADOS (${servicio.estudiantes.length})');
    for (final Estudiante e in servicio.estudiantes) {
      print(' - $e');
      for (final Materia m in e.materias) {
        print('     * $m');
      }
    }
  }

  void _inscribirMateria() {
    final String? registro = _leerObligatorio('Registro del estudiante');
    if (registro == null) return;

    final Estudiante? estudiante = servicio.buscar(registro);
    if (estudiante == null) {
      print('ERROR: no existe un estudiante con el registro $registro.');
      return;
    }

    print('Materias del catalogo:');
    for (int i = 0; i < catalogoMaterias.length; i++) {
      print('  ${i + 1}. ${catalogoMaterias[i]}');
    }
    print('  0. Escribir una materia que no esta en la lista');

    final String? eleccion = _leerObligatorio('Elija una opcion');
    if (eleccion == null) return;

    String codigo;
    String nombreMateria;

    final int? indice = int.tryParse(eleccion);
    if (indice != null && indice >= 1 && indice <= catalogoMaterias.length) {
      final MateriaDisponible disponible = catalogoMaterias[indice - 1];
      codigo = disponible.codigo;
      nombreMateria = disponible.nombre;
    } else if (indice == 0) {
      final String? codigoManual = _leerObligatorio('Codigo de la materia');
      if (codigoManual == null) return;
      final String? nombreManual = _leerObligatorio('Nombre de la materia');
      if (nombreManual == null) return;
      codigo = codigoManual;
      nombreMateria = nombreManual;
    } else {
      print('Opcion no valida.');
      return;
    }

    final Materia materia = servicio.inscribirMateria(
      registro: registro,
      codigoMateria: codigo,
      nombreMateria: nombreMateria,
    );

    print('Materia inscrita a ${estudiante.nombreCompleto}: $materia');
  }

  void _verMateriasDeEstudiante() {
    final String? registro = _leerObligatorio('Registro del estudiante');
    if (registro == null) return;

    final Estudiante? estudiante = servicio.buscar(registro);
    if (estudiante == null) {
      print('ERROR: no existe un estudiante con el registro $registro.');
      return;
    }

    print('\n${estudiante.nombreCompleto} (${estudiante.registro})');
    if (estudiante.materias.isEmpty) {
      print('  No tiene materias inscritas.');
      return;
    }
    for (final Materia m in estudiante.materias) {
      print('  * $m');
    }
  }

  void _darDeBajaMateria() {
    final String? registro = _leerObligatorio('Registro del estudiante');
    if (registro == null) return;

    final String? codigo = _leerObligatorio('Codigo de la materia');
    if (codigo == null) return;

    final bool dadaDeBaja =
        servicio.darDeBajaMateria(registro: registro, codigoMateria: codigo);

    print(dadaDeBaja
        ? 'Materia $codigo dada de baja.'
        : 'El estudiante no tenia inscrita la materia $codigo.');
  }

  void _verJson() {
    if (servicio.vacio) {
      print('No hay datos que serializar.');
      return;
    }
    print('\n${servicio.aJson()}');
  }

  Future<void> _guardar() async {
    final File archivo = await servicio.guardar();
    print('Datos guardados en ${archivo.path}');
  }

  void _cargarEjemplo() {
    if (!servicio.vacio) {
      print('Ya hay datos cargados; los de ejemplo no se agregaron.');
      return;
    }
    servicio.cargarDatosDeEjemplo();
    print('Datos de ejemplo cargados.');
    _listarEstudiantes();
  }

  // --------------------------------------------------------------------
  // Utilidades de entrada
  // --------------------------------------------------------------------

  String? _leer(String etiqueta) {
    stdout.write('$etiqueta: ');
    return stdin.readLineSync();
  }

  /// Pide un texto hasta que no venga vacio. Devuelve `null` si se cierra
  /// la entrada.
  String? _leerObligatorio(String etiqueta) {
    while (true) {
      final String? valor = _leer(etiqueta);
      if (valor == null) return null;
      if (valor.trim().isNotEmpty) return valor.trim();
      print('Este dato es obligatorio.');
    }
  }

  /// Pide una fecha en formato dd/mm/aaaa.
  DateTime? _leerFecha(String etiqueta) {
    while (true) {
      final String? valor = _leerObligatorio(etiqueta);
      if (valor == null) return null;

      final List<String> partes = valor.split(RegExp(r'[/\-]'));
      if (partes.length == 3) {
        final int? dia = int.tryParse(partes[0]);
        final int? mes = int.tryParse(partes[1]);
        final int? anio = int.tryParse(partes[2]);

        if (dia != null && mes != null && anio != null) {
          final DateTime fecha = DateTime(anio, mes, dia);
          final bool valida = fecha.day == dia &&
              fecha.month == mes &&
              fecha.year == anio &&
              fecha.isBefore(DateTime.now());
          if (valida) return fecha;
        }
      }
      print('Fecha no valida. Ejemplo: 15/03/2004');
    }
  }

  static String _fechaHora(DateTime f) => '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/${f.year} '
      '${f.hour.toString().padLeft(2, '0')}:'
      '${f.minute.toString().padLeft(2, '0')}';
}
