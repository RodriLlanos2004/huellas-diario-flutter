# Huellas · Diario personal con foto, voz y ubicación

Aplicación Flutter para el proyecto de **Programación de Dispositivos Móviles** (Universidad Anáhuac Mayab).
Cada día se registra con una foto (cámara o galería), texto dictado por voz, el estado de ánimo y la
ubicación GPS donde se escribió. Todo se guarda localmente en SQLite y el diario está protegido con huella digital.

## Funcionalidades

| Requisito | Implementación |
|---|---|
| Scaffold, AppBar y Drawer | `ListaDiarioPage`, `MapaRecuerdosPage` y `AjustesPage` comparten `AppDrawer` (NavigationDrawer de Material 3). |
| Routes y Navigator | Rutas nombradas en `core/rutas.dart` y generador `onGenerateRoute` en `app.dart` (`/bloqueo`, `/`, `/detalle`, `/nueva`, `/mapa`, `/ajustes`). |
| Animaciones | `Hero` de la miniatura de la lista a la imagen del detalle; `SliverAppBar` expandible; panel de dictado con `AnimatedContainer` y `AnimatedSize`. |
| Persistencia | SQLite (`sqflite`) con la tabla `entradas`: texto, fecha, ánimo, nombre de la imagen, latitud, longitud, precisión y metadatos en JSON. SharedPreferences solo para ajustes. |
| Manejo de errores | `try-catch` en repositorio, servicios de hardware y pantallas; jerarquía `FallaApp` con mensajes para el usuario; `FutureBuilder` con estados de carga, vacío y error con reintento. |
| Cámara y galería | `image_picker`; la foto se copia a la carpeta de documentos de la app. Recupera la foto si Android cierra la app con la cámara abierta. |
| Micrófono y dictado | `speech_to_text` (captura del micrófono + reconocimiento en español) con indicador de nivel de sonido y texto parcial. |
| GPS y mapas | `geolocator` captura la posición al guardar (con límite de tiempo y respaldo); `flutter_map` muestra un mapa interactivo de OpenStreetMap y `url_launcher` abre Google Maps. |
| Login biométrico | `local_auth` al abrir la app y al volver de segundo plano después de 1 minuto; no se puede saltar con el botón Atrás. |
| Permisos negados | Diálogos con explicación, opción de guardar sin ubicación y acceso directo a los ajustes del sistema (`permission_handler`). |
| Serialización JSON | `toJson`/`fromJson` en las entidades y exportación de respaldo completo desde Ajustes. |

## Arquitectura

Feature-First con capas (dominio, datos, presentación) e inversión de dependencias:

```
lib/
├── main.dart                 # Raíz de composición: crea las implementaciones concretas
├── app.dart                  # MaterialApp, rutas nombradas y bloqueo por ciclo de vida
├── core/
│   ├── dependencias.dart     # Contenedor + AppScope (InheritedWidget)
│   ├── errores.dart          # FallaApp y subtipos
│   ├── rutas.dart · tema.dart · fechas.dart
│   ├── dispositivo/          # Interfaces + implementaciones de hardware
│   │   ├── servicio_ubicacion.dart   (geolocator)
│   │   ├── servicio_dictado.dart     (speech_to_text)
│   │   ├── servicio_imagenes.dart    (image_picker)
│   │   ├── servicio_mapas_externos.dart (url_launcher)
│   │   └── servicio_permisos.dart    (permission_handler)
│   └── widgets/              # AppDrawer y estados de vista
└── features/
    ├── diario/
    │   ├── domain/           # EntradaDiario, Ubicacion, MetadatosEntrada, RepositorioDiario
    │   ├── data/             # SQLite, almacén de imágenes, respaldo JSON
    │   └── presentation/     # Páginas y widgets
    ├── seguridad/            # local_auth, preferencias y pantalla de bloqueo
    └── ajustes/
```

Las pantallas dependen solo de interfaces (`RepositorioDiario`, `ServicioUbicacion`, `ServicioDictado`…);
por eso las pruebas de widgets usan versiones falsas sin tocar hardware real.

## Puesta en marcha

Probado con Flutter 3.44 (canal estable) en un emulador Android 17 (API 37).

```bash
flutter pub get
flutter analyze        # sin advertencias
flutter test           # 25 pruebas: serialización, SQLite real en memoria y widgets
flutter run
```

En el emulador: configurar un PIN y una huella en *Ajustes > Seguridad*, fijar la ubicación desde
*Extended controls > Location* (o `adb emu geo fix <lng> <lat>`) y, para dictar, activar
*Virtual microphone uses host audio input*.

## Documentación

- `docs/reporte_tecnico.pdf`: arquitectura (diagramas de clases y flujo de datos), justificación y evidencias.
- `docs/capturas/`: capturas de pantalla de las pruebas en el emulador.
