import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as ph;

/// Accesos directos a los ajustes del sistema, para cuando un permiso
/// quedó negado de forma permanente o un servicio está apagado.
abstract interface class ServicioPermisos {
  Future<bool> abrirAjustesApp();
  Future<bool> abrirAjustesUbicacion();
}

class ServicioPermisosSistema implements ServicioPermisos {
  @override
  Future<bool> abrirAjustesApp() => ph.openAppSettings();

  @override
  Future<bool> abrirAjustesUbicacion() => geo.Geolocator.openLocationSettings();
}
