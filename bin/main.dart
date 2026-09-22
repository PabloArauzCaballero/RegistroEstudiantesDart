import 'package:registro_estudiantes/consola/menu.dart';

Future<void> main(List<String> argumentos) async {
  final Menu menu = Menu();
  await menu.ejecutar();
}
