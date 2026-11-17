import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/ubicacion.dart';

/// Piezas comunes de los mapas interactivos (OpenStreetMap con flutter_map).
/// OpenStreetMap no requiere clave de API, a diferencia del SDK de Google Maps.
abstract final class MapaOsm {
  static LatLng punto(Ubicacion u) => LatLng(u.latitud, u.longitud);

  static TileLayer capaTeselas() => TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        // La política de OpenStreetMap exige identificar la app que pide las teselas.
        userAgentPackageName: 'com.anahuac.huellas',
        maxZoom: 19,
      );

  static Widget atribucion() => const RichAttributionWidget(
        attributions: [TextSourceAttribution('OpenStreetMap contributors')],
      );

  static Marker marcador(LatLng punto, {required Color color, VoidCallback? alTocar}) => Marker(
        point: punto,
        width: 48,
        height: 48,
        alignment: Alignment.topCenter,
        // Contorno blanco con dos íconos superpuestos (en lugar de sombras de texto,
        // que el motor Impeller dibuja en el centro del mapa al aplicar zoom).
        child: GestureDetector(
          onTap: alTocar,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.location_on, size: 48, color: Colors.white),
              Icon(Icons.location_on, size: 40, color: color),
            ],
          ),
        ),
      );

  /// Rotar el mapa no aporta en un diario y confunde; se deja zoom y desplazamiento.
  static const interaccion =
      InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate);
}

/// Mapa interactivo con un solo marcador, usado en el detalle de una entrada.
class MapaUbicacion extends StatelessWidget {
  const MapaUbicacion({super.key, required this.ubicacion, this.alto = 240});

  final Ubicacion ubicacion;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final centro = MapaOsm.punto(ubicacion);
    final precision = ubicacion.precisionMetros;
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: alto,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: centro,
            initialZoom: 16,
            interactionOptions: MapaOsm.interaccion,
          ),
          children: [
            MapaOsm.capaTeselas(),
            if (precision != null && precision > 0)
              CircleLayer(circles: [
                CircleMarker(
                  point: centro,
                  radius: precision,
                  useRadiusInMeter: true,
                  color: color.withValues(alpha: 0.15),
                  borderColor: color.withValues(alpha: 0.5),
                  borderStrokeWidth: 1.5,
                ),
              ]),
            MarkerLayer(markers: [MapaOsm.marcador(centro, color: color)]),
            MapaOsm.atribucion(),
          ],
        ),
      ),
    );
  }
}
