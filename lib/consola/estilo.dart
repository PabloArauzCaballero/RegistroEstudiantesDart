import 'dart:io';

/// Utilidades de presentación para la consola: color ANSI, paneles y tablas.
///
/// Si la salida no es una terminal (por ejemplo al redirigir a un archivo o
/// pasar la salida por una tubería) se escribe texto plano, sin códigos de
/// color, para que el resultado siga siendo legible.
class Estilo {
  Estilo._();

  static final bool colorActivo = stdout.supportsAnsiEscapes;

  static const String _reset = '\x1B[0m';
  static final RegExp _codigosAnsi = RegExp('\x1B\\[[0-9;]*m');

  static String _pintar(String texto, String codigo) =>
      colorActivo ? '\x1B[${codigo}m$texto$_reset' : texto;

  // Paleta -------------------------------------------------------------
  static String negrita(String t) => _pintar(t, '1');
  static String tenue(String t) => _pintar(t, '2');
  static String primario(String t) => _pintar(t, '96'); // cian brillante
  static String acento(String t) => _pintar(t, '95'); // magenta brillante
  static String exito(String t) => _pintar(t, '92'); // verde
  static String error(String t) => _pintar(t, '91'); // rojo
  static String aviso(String t) => _pintar(t, '93'); // amarillo
  static String dato(String t) => _pintar(t, '94'); // azul

  // Símbolos -----------------------------------------------------------
  static const String flecha = '❯';
  static const String ramaMedia = '├─';
  static const String ramaFinal = '└─';

  /// Ancho visible del texto, ignorando los códigos de color.
  static int ancho(String texto) => texto.replaceAll(_codigosAnsi, '').length;

  /// Rellena con espacios a la derecha hasta [columnas] de ancho visible.
  static String rellenar(String texto, int columnas) {
    final int faltan = columnas - ancho(texto);
    return faltan > 0 ? '$texto${' ' * faltan}' : texto;
  }

  /// Rellena con espacios a la izquierda (para números alineados a la derecha).
  static String rellenarIzquierda(String texto, int columnas) {
    final int faltan = columnas - ancho(texto);
    return faltan > 0 ? '${' ' * faltan}$texto' : texto;
  }

  /// Panel con borde redondeado y título opcional.
  static String panel(
    List<String> lineas, {
    String? titulo,
    int anchoMinimo = 46,
  }) {
    final int anchoContenido = <int>[
      anchoMinimo,
      if (titulo != null) ancho(titulo) + 4,
      ...lineas.map(ancho),
    ].reduce((int a, int b) => a > b ? a : b);

    final StringBuffer salida = StringBuffer();

    if (titulo == null) {
      salida.writeln(primario('╭${'─' * (anchoContenido + 2)}╮'));
    } else {
      final int guiones = anchoContenido - ancho(titulo) - 1;
      salida.writeln(
        '${primario('╭─')} ${negrita(primario(titulo))} '
        '${primario('${'─' * guiones}╮')}',
      );
    }

    for (final String linea in lineas) {
      salida.writeln(
        '${primario('│')} ${rellenar(linea, anchoContenido)} ${primario('│')}',
      );
    }

    salida.write(primario('╰${'─' * (anchoContenido + 2)}╯'));
    return salida.toString();
  }

  /// Tabla con encabezado subrayado. [derecha] lista las columnas numéricas,
  /// que se alinean a la derecha.
  static String tabla({
    required List<String> encabezados,
    required List<List<String>> filas,
    List<int> derecha = const <int>[],
  }) {
    final List<int> anchos = <int>[
      for (int i = 0; i < encabezados.length; i++)
        <int>[
          ancho(encabezados[i]),
          ...filas.map((List<String> f) => ancho(f[i])),
        ].reduce((int a, int b) => a > b ? a : b),
    ];

    String componer(List<String> celdas) {
      final List<String> partes = <String>[
        for (int i = 0; i < celdas.length; i++)
          derecha.contains(i)
              ? rellenarIzquierda(celdas[i], anchos[i])
              : rellenar(celdas[i], anchos[i]),
      ];
      return '  ${partes.join('   ')}'.trimRight();
    }

    final int anchoTotal =
        anchos.reduce((int a, int b) => a + b) + 3 * (anchos.length - 1);

    final StringBuffer salida = StringBuffer()
      ..writeln(negrita(primario(componer(encabezados))))
      ..writeln(tenue('  ${'─' * anchoTotal}'));

    for (final List<String> fila in filas) {
      salida.writeln(componer(fila));
    }
    return salida.toString().trimRight();
  }

  // Mensajes -----------------------------------------------------------
  static String mensajeExito(String t) => '  ${exito('✓')} $t';
  static String mensajeError(String t) => '  ${error('✗')} $t';
  static String mensajeAviso(String t) => '  ${aviso('!')} $t';
  static String mensajeInfo(String t) => '  ${dato('i')} $t';

  /// Colorea un JSON ya formateado: claves en cian y textos en verde.
  static String resaltarJson(String json) {
    if (!colorActivo) return json;
    return json
        .replaceAllMapped(
          RegExp('"([^"]+)":'),
          (Match m) => '${primario('"${m[1]}"')}:',
        )
        .replaceAllMapped(
          RegExp(': "([^"]*)"'),
          (Match m) => ': ${exito('"${m[1]}"')}',
        );
  }

  static void limpiarPantalla() {
    if (colorActivo) stdout.write('\x1B[2J\x1B[H');
  }
}
