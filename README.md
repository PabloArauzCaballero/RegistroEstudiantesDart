# Sistema de Registro de Estudiantes (Dart, consola)

Aplicacion de consola en Dart para registrar estudiantes y las materias que
inscriben. Un estudiante puede tener varias materias.

## Ejecutar

```bash
dart pub get
dart run bin/main.dart
```

En el menu, la opcion **8** carga datos de ejemplo para probar rapido.
Al salir (opcion **0**) los datos se guardan en `datos/estudiantes.json` y se
vuelven a cargar en el siguiente arranque.

## Estructura

```
bin/main.dart                        punto de entrada
lib/modelos/estudiante.dart          clase Estudiante
lib/modelos/materia.dart             clase Materia + catalogo const
lib/servicios/registro_servicio.dart logica de registro y persistencia JSON
lib/consola/menu.dart                menu de consola
```

## Modelo

| Clase | Propiedades |
|---|---|
| `Estudiante` | `registro`, `fechaNacimiento`, `nombre`, `apellido`, lista de `Materia` |
| `Materia` | `codigoMateria`, `fechaRegistro`, `estudiante`, `nombreMateria` |

La relacion es bidireccional: el estudiante conoce sus materias y cada materia
conoce al estudiante que la inscribio.

## Requisitos del practico y donde se cumplen

**1. Constructores con parametros nombrados requeridos (`required`)**

```dart
Estudiante({
  required this.registro,
  required this.fechaNacimiento,
  required this.nombre,
  required this.apellido,
});
```

Lo mismo en `Materia`, en `MateriaDisponible` y en los metodos
`registrarEstudiante(...)` / `inscribirMateria(...)` del servicio.

**2. Constructores factoria `factory Nombrado.fromJson` sobre `Map<String, dynamic>`**

- `Estudiante.fromJson(Map<String, dynamic> json)` reconstruye al estudiante y
  todas sus materias.
- `Materia.fromJson(Map<String, dynamic> json, {Estudiante? estudiante})`
  admite que el estudiante venga dentro del mapa o ya construido.
- El camino de vuelta son `toJson()` en ambas clases. Como la relacion es
  circular (estudiante -> materias -> estudiante), `toJson` recibe una bandera
  (`incluirMaterias` / `incluirEstudiante`) para cortar la recursion.

**3. Mutabilidad y ciclo de vida de variables**

- `final`: todas las propiedades de `Estudiante` y `Materia`, y la lista
  `_materias` (la lista es siempre la misma; lo que cambia es su contenido).
- `const`: `MateriaDisponible` tiene constructor `const` y el catalogo
  `catalogoMaterias` es una lista `const`; ademas constantes como
  `RegistroServicio.rutaPorDefecto`.
- `late`: `Estudiante.nombreCompleto` (`late final` con inicializador diferido,
  se arma la primera vez que se usa), `RegistroServicio._archivo` (se asigna en
  el cuerpo del constructor) y `Menu._inicioSesion` (se asigna al arrancar).

## Ejemplo del JSON generado

```json
[
  {
    "registro": "223001",
    "nombre": "Ana",
    "apellido": "Quiroga",
    "fechaNacimiento": "2004-03-15T00:00:00.000",
    "materias": [
      {
        "codigoMateria": "SI-220",
        "nombreMateria": "Fundamentos de Programacion",
        "fechaRegistro": "2026-02-10T00:00:00.000"
      }
    ]
  }
]
```
