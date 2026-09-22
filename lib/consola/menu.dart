import 'dart:io';

import '../modelos/estudiante.dart';
import '../modelos/materia.dart';
import '../servicios/registro_servicio.dart';
import 'estilo.dart';

/// Una entrada del menú principal.
class OpcionMenu {
  final String tecla;
  final String titulo;

  const OpcionMenu({required this.tecla, required this.titulo});
}

/// Menú de consola del sistema de registro.
class Menu {
  static const List<OpcionMenu> opciones = <OpcionMenu>[
    OpcionMenu(tecla: '1', titulo: 'Registrar estudiante'),
    OpcionMenu(tecla: '2', titulo: 'Listar estudiantes'),
    OpcionMenu(tecla: '3', titulo: 'Inscribir materia'),
    OpcionMenu(tecla: '4', titulo: 'Ver ficha de un estudiante'),
    OpcionMenu(tecla: '5', titulo: 'Dar de baja una materia'),
    OpcionMenu(tecla: '6', titulo: 'Ver los datos en JSON'),
    OpcionMenu(tecla: '7', titulo: 'Guardar en archivo'),
    OpcionMenu(tecla: '8', titulo: 'Cargar datos de ejemplo'),
    OpcionMenu(tecla: '0', titulo: 'Salir'),
  ];

  final RegistroServicio servicio;

  /// `late final`: se asigna una sola vez, cuando arranca [ejecutar].
  late final DateTime _inicioSesion;

  Menu({RegistroServicio? servicio})
      : servicio = servicio ?? RegistroServicio();

  Future<void> ejecutar() async {
    _inicioSesion = DateTime.now();

    final int cargados = await servicio.cargar();

    Estilo.limpiarPantalla();
    _portada(cargados);

    bool salir = false;
    while (!salir) {
      _mostrarMenu();
      final String? opcion = _leer('Opción');

      // Entrada cerrada (Ctrl+D o datos por tubería): se termina.
      if (opcion == null) {
        print('\n${Estilo.mensajeAviso('Entrada cerrada. Saliendo...')}');
        break;
      }

      print('');
      try {
        switch (opcion.trim()) {
          case '1':
            _registrarEstudiante();
          case '2':
            _listarEstudiantes();
          case '3':
            _inscribirMateria();
          case '4':
            _verFicha();
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
            print(Estilo.mensajeError('Opción no válida.'));
        }
      } on StateError catch (e) {
        print(Estilo.mensajeError(e.message));
      } on ArgumentError catch (e) {
        print(Estilo.mensajeError('${e.message}'));
      } on FormatException catch (e) {
        print(Estilo.mensajeError('Formato inválido: ${e.message}'));
      }
    }

    if (salir) {
      await servicio.guardar();
      print('');
      print(Estilo.mensajeExito('Datos guardados en ${servicio.rutaArchivo}'));
      print('  ${Estilo.tenue('Hasta luego.')}\n');
    }
  }

  // --------------------------------------------------------------------
  // Pantallas
  // --------------------------------------------------------------------

  void _portada(int cargados) {
    print('');
    print(
      Estilo.panel(
        <String>[
          '',
          Estilo.tenue(
              'Estudiantes y materias · aplicación de consola en Dart'),
          '',
          '${Estilo.tenue('Sesión iniciada  ')}${_fechaHora(_inicioSesion)}',
          '${Estilo.tenue('Archivo de datos ')}${servicio.rutaArchivo}',
          if (cargados > 0)
            '${Estilo.tenue('Cargados         ')}'
                '${Estilo.exito('$cargados estudiante(s) del archivo')}',
          '',
        ],
        titulo: 'SISTEMA DE REGISTRO DE ESTUDIANTES',
      ),
    );
  }

  void _mostrarMenu() {
    final int inscripciones = servicio.todasLasMaterias().length;

    print('');
    print(
      Estilo.panel(
        <String>[
          '',
          for (final OpcionMenu o in opciones)
            '  ${Estilo.acento(o.tecla)}   ${o.titulo}',
          '',
          Estilo.tenue(
            '  ${servicio.estudiantes.length} estudiante(s) · '
            '$inscripciones inscripción(es)',
          ),
        ],
        titulo: 'MENÚ PRINCIPAL',
      ),
    );
    print('');
  }

  void _registrarEstudiante() {
    print(Estilo.negrita('  REGISTRAR ESTUDIANTE'));
    print('');

    final String? registro = _leerObligatorio('Número de registro');
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

    print('');
    print(
      Estilo.mensajeExito(
        'Estudiante registrado: '
        '${Estilo.negrita(estudiante.nombreCompleto)} '
        '${Estilo.tenue('(${estudiante.registro})')}',
      ),
    );
  }

  void _listarEstudiantes() {
    if (servicio.vacio) {
      print(Estilo.mensajeAviso('Todavía no hay estudiantes registrados.'));
      print(
        '  ${Estilo.tenue('Use la opción 1 para registrar, o la 8 para datos de ejemplo.')}',
      );
      return;
    }

    print(
      Estilo.negrita('  ESTUDIANTES REGISTRADOS ') +
          Estilo.tenue('(${servicio.estudiantes.length})'),
    );
    print('');
    print(
      Estilo.tabla(
        encabezados: <String>['REGISTRO', 'ESTUDIANTE', 'EDAD', 'MATERIAS'],
        filas: <List<String>>[
          for (final Estudiante e in servicio.estudiantes)
            <String>[
              e.registro,
              e.nombreCompleto,
              '${e.edad}',
              '${e.cantidadMaterias}',
            ],
        ],
        derecha: <int>[2, 3],
      ),
    );

    print('');
    for (final Estudiante e in servicio.estudiantes) {
      _arbolMaterias(e);
    }
  }

  /// Dibuja al estudiante y sus materias como un árbol.
  void _arbolMaterias(Estudiante estudiante) {
    print(
      '  ${Estilo.acento(Estilo.flecha)} '
      '${Estilo.negrita(estudiante.registro)}  '
      '${estudiante.nombreCompleto}',
    );

    if (estudiante.materias.isEmpty) {
      print(
          '     ${Estilo.tenue('${Estilo.ramaFinal} sin materias inscritas')}');
      print('');
      return;
    }

    final List<Materia> materias = estudiante.materias;
    final int anchoCodigo = materias
        .map((Materia m) => m.codigoMateria.length)
        .reduce((int a, int b) => a > b ? a : b);
    final int anchoNombre = materias
        .map((Materia m) => m.nombreMateria.length)
        .reduce((int a, int b) => a > b ? a : b);

    for (int i = 0; i < materias.length; i++) {
      final Materia m = materias[i];
      final bool ultima = i == materias.length - 1;
      print(
        '     ${Estilo.tenue(ultima ? Estilo.ramaFinal : Estilo.ramaMedia)} '
        '${Estilo.dato(Estilo.rellenar(m.codigoMateria, anchoCodigo))}  '
        '${Estilo.rellenar(m.nombreMateria, anchoNombre)}  '
        '${Estilo.tenue('inscrita ${_soloFecha(m.fechaRegistro)}')}',
      );
    }
    print('');
  }

  void _inscribirMateria() {
    print(Estilo.negrita('  INSCRIBIR MATERIA'));
    print('');

    final String? registro = _leerObligatorio('Registro del estudiante');
    if (registro == null) return;

    final Estudiante? estudiante = servicio.buscar(registro);
    if (estudiante == null) {
      print(
        Estilo.mensajeError(
            'No existe un estudiante con el registro $registro.'),
      );
      return;
    }

    print('');
    print(
        '  ${Estilo.tenue('Estudiante:')} ${Estilo.negrita(estudiante.nombreCompleto)}');
    print('');
    print(
      Estilo.tabla(
        encabezados: <String>['#', 'CÓDIGO', 'MATERIA'],
        filas: <List<String>>[
          for (int i = 0; i < catalogoMaterias.length; i++)
            <String>[
              Estilo.acento('${i + 1}'),
              catalogoMaterias[i].codigo,
              catalogoMaterias[i].nombre,
            ],
          <String>[Estilo.acento('0'), '—', 'Otra materia (escribirla a mano)'],
        ],
      ),
    );
    print('');

    final String? eleccion = _leerObligatorio('Elija una opción');
    if (eleccion == null) return;

    String codigo;
    String nombreMateria;

    final int? indice = int.tryParse(eleccion);
    if (indice != null && indice >= 1 && indice <= catalogoMaterias.length) {
      final MateriaDisponible disponible = catalogoMaterias[indice - 1];
      codigo = disponible.codigo;
      nombreMateria = disponible.nombre;
    } else if (indice == 0) {
      final String? codigoManual = _leerObligatorio('Código de la materia');
      if (codigoManual == null) return;
      final String? nombreManual = _leerObligatorio('Nombre de la materia');
      if (nombreManual == null) return;
      codigo = codigoManual;
      nombreMateria = nombreManual;
    } else {
      print(Estilo.mensajeError('Opción no válida.'));
      return;
    }

    final Materia materia = servicio.inscribirMateria(
      registro: registro,
      codigoMateria: codigo,
      nombreMateria: nombreMateria,
    );

    print('');
    print(
      Estilo.mensajeExito(
        'Materia inscrita a ${Estilo.negrita(estudiante.nombreCompleto)}: '
        '${Estilo.dato(materia.codigoMateria)} ${materia.nombreMateria}',
      ),
    );
  }

  void _verFicha() {
    final String? registro = _leerObligatorio('Registro del estudiante');
    if (registro == null) return;

    final Estudiante? e = servicio.buscar(registro);
    if (e == null) {
      print(
        Estilo.mensajeError(
            'No existe un estudiante con el registro $registro.'),
      );
      return;
    }

    print('');
    print(
      Estilo.panel(
        <String>[
          '',
          '${Estilo.tenue('Registro     ')}${Estilo.negrita(e.registro)}',
          '${Estilo.tenue('Nombre       ')}${e.nombreCompleto}',
          '${Estilo.tenue('Nacimiento   ')}${_soloFecha(e.fechaNacimiento)} '
              '${Estilo.tenue('(${e.edad} años)')}',
          '${Estilo.tenue('Materias     ')}${e.cantidadMaterias}',
          '',
        ],
        titulo: 'FICHA DEL ESTUDIANTE',
      ),
    );
    print('');
    _arbolMaterias(e);
  }

  void _darDeBajaMateria() {
    final String? registro = _leerObligatorio('Registro del estudiante');
    if (registro == null) return;

    final String? codigo = _leerObligatorio('Código de la materia');
    if (codigo == null) return;

    final bool dadaDeBaja = servicio.darDeBajaMateria(
      registro: registro,
      codigoMateria: codigo,
    );

    print('');
    print(
      dadaDeBaja
          ? Estilo.mensajeExito('Materia ${codigo.toUpperCase()} dada de baja.')
          : Estilo.mensajeAviso(
              'El estudiante no tenía inscrita la materia ${codigo.toUpperCase()}.',
            ),
    );
  }

  void _verJson() {
    if (servicio.vacio) {
      print(Estilo.mensajeAviso('No hay datos que serializar.'));
      return;
    }
    print(Estilo.negrita('  DATOS SERIALIZADOS (JSON)'));
    print('');
    print(Estilo.resaltarJson(servicio.aJson()));
  }

  Future<void> _guardar() async {
    final File archivo = await servicio.guardar();
    print(Estilo.mensajeExito('Datos guardados en ${archivo.path}'));
  }

  void _cargarEjemplo() {
    if (!servicio.vacio) {
      print(
        Estilo.mensajeAviso(
            'Ya hay datos cargados; no se agregaron los de ejemplo.'),
      );
      return;
    }
    servicio.cargarDatosDeEjemplo();
    print(Estilo.mensajeExito('Datos de ejemplo cargados.'));
    print('');
    _listarEstudiantes();
  }

  // --------------------------------------------------------------------
  // Utilidades de entrada
  // --------------------------------------------------------------------

  String? _leer(String etiqueta) {
    stdout.write('  ${Estilo.acento(Estilo.flecha)} $etiqueta: ');
    return stdin.readLineSync();
  }

  /// Pide un texto hasta que no venga vacío. Devuelve `null` si se cierra
  /// la entrada.
  String? _leerObligatorio(String etiqueta) {
    while (true) {
      final String? valor = _leer(etiqueta);
      if (valor == null) return null;
      if (valor.trim().isNotEmpty) return valor.trim();
      print(Estilo.mensajeError('Este dato es obligatorio.'));
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
      print(Estilo.mensajeError('Fecha no válida. Ejemplo: 15/03/2004'));
    }
  }

  static String _soloFecha(DateTime f) => '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/${f.year}';

  static String _fechaHora(DateTime f) =>
      '${_soloFecha(f)} ${f.hour.toString().padLeft(2, '0')}:'
      '${f.minute.toString().padLeft(2, '0')}';
}
