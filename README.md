# Sistema de Registro de Estudiantes (Dart, consola)

Aplicación de consola en Dart para registrar estudiantes y las materias que
inscriben. Un estudiante puede tener varias materias.

## Ejecutar

```bash
dart pub get
dart run bin/main.dart
```

En el menú, la opción **8** carga datos de ejemplo para probar rápido.
Al salir (opción **0**) los datos se guardan en `datos/estudiantes.json` y se
vuelven a cargar en el siguiente arranque.

## Así se ve

```
╭─ SISTEMA DE REGISTRO DE ESTUDIANTES ───────────────────╮
│                                                        │
│ Estudiantes y materias · aplicación de consola en Dart │
│                                                        │
│ Sesión iniciada  21/09/2026 23:09                      │
│ Archivo de datos datos/estudiantes.json                │
│                                                        │
╰────────────────────────────────────────────────────────╯

╭─ MENÚ PRINCIPAL ───────────────────────────────╮
│                                                │
│   1   Registrar estudiante                     │
│   2   Listar estudiantes                       │
│   3   Inscribir materia                        │
│   4   Ver ficha de un estudiante               │
│   5   Dar de baja una materia                  │
│   6   Ver los datos en JSON                    │
│   7   Guardar en archivo                       │
│   8   Cargar datos de ejemplo                  │
│   0   Salir                                    │
│                                                │
│   2 estudiante(s) · 3 inscripción(es)          │
╰────────────────────────────────────────────────╯

  ❯ Opción: 2

  ESTUDIANTES REGISTRADOS (2)

  REGISTRO   ESTUDIANTE     EDAD   MATERIAS
  ─────────────────────────────────────────
  223001     Ana Quiroga      22          2
  223002     Luis Mendoza     22          1

  ❯ 223001  Ana Quiroga
     ├─ SI-220   Fundamentos de Programación  inscrita 10/02/2026
     └─ MAT-101  Cálculo I                    inscrita 10/02/2026

  ❯ 223002  Luis Mendoza
     └─ SI-330  Base de Datos I  inscrita 12/02/2026
```

En una terminal real esto sale en color: paneles y encabezados en cian, las
teclas del menú en magenta, los avisos de éxito en verde y los errores en rojo.
Si la salida se redirige a un archivo o a otra orden, el color se apaga solo y
queda texto plano.

## Estructura

```
bin/main.dart                        punto de entrada
lib/modelos/estudiante.dart          clase Estudiante
lib/modelos/materia.dart             clase Materia + catálogo const
lib/servicios/registro_servicio.dart lógica de registro y persistencia JSON
lib/consola/menu.dart                menú de consola
lib/consola/estilo.dart              color ANSI, paneles y tablas
```

## Modelo

| Clase | Propiedades |
|---|---|
| `Estudiante` | `registro`, `fechaNacimiento`, `nombre`, `apellido`, lista de `Materia` |
| `Materia` | `codigoMateria`, `fechaRegistro`, `estudiante`, `nombreMateria` |

La relación es bidireccional: el estudiante conoce sus materias y cada materia
conoce al estudiante que la inscribió.

## Requisitos del práctico y dónde se cumplen

**1. Constructores con parámetros nombrados requeridos (`required`)**

```dart
Estudiante({
  required this.registro,
  required this.fechaNacimiento,
  required this.nombre,
  required this.apellido,
});
```

Lo mismo en `Materia`, en `MateriaDisponible` y en los métodos
`registrarEstudiante(...)` / `inscribirMateria(...)` del servicio.

**2. Constructores factoría `factory Nombrado.fromJson` sobre `Map<String, dynamic>`**

- `Estudiante.fromJson(Map<String, dynamic> json)` reconstruye al estudiante y
  todas sus materias.
- `Materia.fromJson(Map<String, dynamic> json, {Estudiante? estudiante})`
  admite que el estudiante venga dentro del mapa o ya construido.
- El camino de vuelta son `toJson()` en ambas clases. Como la relación es
  circular (estudiante -> materias -> estudiante), `toJson` recibe una bandera
  (`incluirMaterias` / `incluirEstudiante`) para cortar la recursión.

**3. Mutabilidad y ciclo de vida de variables**

- `final`: todas las propiedades de `Estudiante` y `Materia`, y la lista
  `_materias` (la lista es siempre la misma; lo que cambia es su contenido).
- `const`: `MateriaDisponible` tiene constructor `const` y el catálogo
  `catalogoMaterias` es una lista `const`; lo mismo `Menu.opciones` (lista
  `const` de `OpcionMenu`) y constantes como `RegistroServicio.rutaPorDefecto`.
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
        "nombreMateria": "Fundamentos de Programación",
        "fechaRegistro": "2026-02-10T00:00:00.000"
      }
    ]
  }
]
```
