/// Coordenadas GPS capturadas al guardar una entrada.
class Ubicacion {
  const Ubicacion({required this.latitud, required this.longitud, this.precisionMetros});

  final double latitud;
  final double longitud;

  /// Radio de error reportado por el GPS, en metros.
  final double? precisionMetros;

  String get coordenadasTexto => '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}';

  /// Enlace universal de Google Maps (funciona en Android, iOS y web).
  Uri get enlaceGoogleMaps => Uri.https(
        'www.google.com',
        '/maps/search/',
        {'api': '1', 'query': '$latitud,$longitud'},
      );

  Map<String, dynamic> toJson() => {
        'latitud': latitud,
        'longitud': longitud,
        if (precisionMetros != null) 'precisionMetros': precisionMetros,
      };

  factory Ubicacion.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitud'] as num).toDouble();
    final lng = (json['longitud'] as num).toDouble();
    if (lat.abs() > 90 || lng.abs() > 180) {
      throw FormatException('Coordenadas fuera de rango: $lat, $lng');
    }
    return Ubicacion(
      latitud: lat,
      longitud: lng,
      precisionMetros: (json['precisionMetros'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Ubicacion &&
      other.latitud == latitud &&
      other.longitud == longitud &&
      other.precisionMetros == precisionMetros;

  @override
  int get hashCode => Object.hash(latitud, longitud, precisionMetros);
}
