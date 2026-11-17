import 'estado_animo.dart';
import 'metadatos_entrada.dart';
import 'ubicacion.dart';

/// Entidad principal: un día registrado en el diario.
///
/// Es inmutable; para modificarla se usa [copyWith]. Sabe convertirse a
/// un mapa de SQLite ([toMap]/[EntradaDiario.fromMap]) y a JSON
/// ([toJson]/[EntradaDiario.fromJson]) para el respaldo exportable.
class EntradaDiario {
  const EntradaDiario({
    this.id,
    required this.titulo,
    required this.texto,
    required this.fecha,
    this.animo = EstadoAnimo.tranquilo,
    this.imagen,
    this.ubicacion,
    this.metadatos = const MetadatosEntrada(),
  });

  /// Clave primaria en SQLite; es null mientras la entrada no se ha guardado.
  final int? id;
  final String titulo;
  final String texto;
  final DateTime fecha;
  final EstadoAnimo animo;

  /// Nombre del archivo de imagen dentro de la carpeta privada de la app.
  /// Se guarda solo el nombre, no la ruta absoluta, porque en iOS la ruta
  /// del contenedor de la app cambia entre instalaciones y actualizaciones.
  final String? imagen;
  final Ubicacion? ubicacion;
  final MetadatosEntrada metadatos;

  bool get tieneImagen => imagen != null;
  bool get tieneUbicacion => ubicacion != null;

  /// Etiqueta compartida por el Hero de la lista y el del detalle.
  String get etiquetaHero => 'huella-imagen-${id ?? fecha.microsecondsSinceEpoch}';

  EntradaDiario copyWith({
    int? id,
    String? titulo,
    String? texto,
    DateTime? fecha,
    EstadoAnimo? animo,
    String? imagen,
    Ubicacion? ubicacion,
    MetadatosEntrada? metadatos,
  }) =>
      EntradaDiario(
        id: id ?? this.id,
        titulo: titulo ?? this.titulo,
        texto: texto ?? this.texto,
        fecha: fecha ?? this.fecha,
        animo: animo ?? this.animo,
        imagen: imagen ?? this.imagen,
        ubicacion: ubicacion ?? this.ubicacion,
        metadatos: metadatos ?? this.metadatos,
      );

  // ---------- SQLite ----------

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'titulo': titulo,
        'texto': texto,
        'fecha': fecha.millisecondsSinceEpoch,
        'animo': animo.name,
        'imagen': imagen,
        'latitud': ubicacion?.latitud,
        'longitud': ubicacion?.longitud,
        'precision_m': ubicacion?.precisionMetros,
        'metadatos': metadatos.aTexto(),
      };

  factory EntradaDiario.fromMap(Map<String, Object?> mapa) {
    final lat = mapa['latitud'] as num?;
    final lng = mapa['longitud'] as num?;
    return EntradaDiario(
      id: mapa['id'] as int?,
      titulo: mapa['titulo'] as String,
      texto: mapa['texto'] as String,
      fecha: DateTime.fromMillisecondsSinceEpoch(mapa['fecha'] as int),
      animo: EstadoAnimo.desdeNombre(mapa['animo'] as String?),
      imagen: mapa['imagen'] as String?,
      ubicacion: (lat == null || lng == null)
          ? null
          : Ubicacion(
              latitud: lat.toDouble(),
              longitud: lng.toDouble(),
              precisionMetros: (mapa['precision_m'] as num?)?.toDouble(),
            ),
      metadatos: MetadatosEntrada.desdeTexto(mapa['metadatos'] as String?),
    );
  }

  // ---------- JSON ----------

  Map<String, dynamic> toJson() => {
        'id': id,
        'titulo': titulo,
        'texto': texto,
        'fecha': fecha.toIso8601String(),
        'animo': animo.name,
        'imagen': imagen,
        'ubicacion': ubicacion?.toJson(),
        'metadatos': metadatos.toJson(),
      };

  factory EntradaDiario.fromJson(Map<String, dynamic> json) => EntradaDiario(
        id: json['id'] as int?,
        titulo: json['titulo'] as String,
        texto: json['texto'] as String,
        fecha: DateTime.parse(json['fecha'] as String),
        animo: EstadoAnimo.desdeNombre(json['animo'] as String?),
        imagen: json['imagen'] as String?,
        ubicacion: json['ubicacion'] == null
            ? null
            : Ubicacion.fromJson(json['ubicacion'] as Map<String, dynamic>),
        metadatos: json['metadatos'] == null
            ? const MetadatosEntrada()
            : MetadatosEntrada.fromJson(json['metadatos'] as Map<String, dynamic>),
      );
}
