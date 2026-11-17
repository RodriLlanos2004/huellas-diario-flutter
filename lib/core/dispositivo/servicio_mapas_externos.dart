import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/diario/domain/ubicacion.dart';

/// Contrato para abrir una ubicación en una app de mapas externa.
abstract interface class ServicioMapasExternos {
  /// Devuelve false si no hay ninguna app capaz de abrir el enlace.
  Future<bool> abrir(Ubicacion ubicacion);
}

/// Abre Google Maps con el enlace universal `https://www.google.com/maps/search/?api=1&query=lat,lng`.
/// Si la app de Google Maps está instalada, el sistema la abre; si no, se usa el navegador.
class ServicioMapasUrlLauncher implements ServicioMapasExternos {
  @override
  Future<bool> abrir(Ubicacion ubicacion) async {
    try {
      final enApp = await launchUrl(ubicacion.enlaceGoogleMaps, mode: LaunchMode.externalApplication);
      if (enApp) return true;
      return await launchUrl(ubicacion.enlaceGoogleMaps);
    } on PlatformException {
      return false;
    }
  }
}
