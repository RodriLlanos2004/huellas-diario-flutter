import 'dart:convert';

/// De dónde salió la imagen de la entrada.
enum OrigenImagen {
  camara('Cámara'),
  galeria('Galería');

  const OrigenImagen(this.etiqueta);
  final String etiqueta;
}

/// Información adicional de una entrada que se guarda como JSON en una
/// sola columna de SQLite. Permite agregar campos nuevos sin migrar la tabla.
class MetadatosEntrada {
  const MetadatosEntrada({this.origenImagen, this.usoDictado = false, this.segundosDictado = 0});

  final OrigenImagen? origenImagen;
  final bool usoDictado;
  final int segundosDictado;

  Map<String, dynamic> toJson() => {
        if (origenImagen != null) 'origenImagen': origenImagen!.name,
        'usoDictado': usoDictado,
        'segundosDictado': segundosDictado,
      };

  factory MetadatosEntrada.fromJson(Map<String, dynamic> json) {
    final origen = json['origenImagen'] as String?;
    return MetadatosEntrada(
      origenImagen: OrigenImagen.values.where((o) => o.name == origen).firstOrNull,
      usoDictado: json['usoDictado'] as bool? ?? false,
      segundosDictado: (json['segundosDictado'] as num?)?.toInt() ?? 0,
    );
  }

  /// Lee el texto de la columna `metadatos`. Si el JSON está dañado no
  /// rompe la lectura del registro: devuelve metadatos vacíos.
  static MetadatosEntrada desdeTexto(String? texto) {
    if (texto == null || texto.isEmpty) return const MetadatosEntrada();
    try {
      return MetadatosEntrada.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } on FormatException {
      return const MetadatosEntrada();
    } on TypeError {
      return const MetadatosEntrada();
    }
  }

  String aTexto() => jsonEncode(toJson());
}
