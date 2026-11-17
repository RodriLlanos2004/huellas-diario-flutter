import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../../features/diario/domain/ubicacion.dart';
import '../errores.dart';

/// Contrato para obtener la posición actual del dispositivo.
abstract interface class ServicioUbicacion {
  /// Devuelve la posición actual o lanza una [FallaApp] con la causa:
  /// GPS apagado, permiso negado o tiempo agotado.
  Future<Ubicacion> obtenerActual({Duration limite});
}

/// Implementación con el paquete `geolocator`.
class ServicioUbicacionGeolocator implements ServicioUbicacion {
  @override
  Future<Ubicacion> obtenerActual({Duration limite = const Duration(seconds: 12)}) async {
    // 1. El servicio de ubicación del sistema debe estar encendido.
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const FallaServicioDesactivado(
          'La ubicación del dispositivo está apagada. Actívala para guardar dónde estabas.');
    }

    // 2. Permiso en tiempo de ejecución: se pide solo si aún no se ha decidido.
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.deniedForever) {
      throw const FallaPermiso(
          'El permiso de ubicación está bloqueado. Actívalo en los ajustes de la app.',
          permanente: true);
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.unableToDetermine) {
      throw const FallaPermiso('Sin permiso de ubicación no puedo guardar el lugar de tu entrada.');
    }

    // 3. Lectura con límite de tiempo para que la UI nunca se quede esperando.
    try {
      // En Android se lee directamente el GPS (LocationManager) en lugar del
      // proveedor fusionado de Google Play Services: así se obtiene una
      // lectura nueva en cada guardado y no depende de servicios de Google.
      final ajustes = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: limite,
              forceLocationManager: true,
            )
          : LocationSettings(accuracy: LocationAccuracy.high, timeLimit: limite);
      final posicion = await Geolocator.getCurrentPosition(locationSettings: ajustes);
      return _convertir(posicion);
    } on TimeoutException {
      // Respaldo: la última posición conocida es mejor que no guardar nada.
      final ultima = await Geolocator.getLastKnownPosition();
      if (ultima != null) return _convertir(ultima);
      throw FallaTiempoAgotado(
          'El GPS no respondió en ${limite.inSeconds} segundos. Intenta en un lugar más abierto.');
    } on LocationServiceDisabledException {
      throw const FallaServicioDesactivado('La ubicación se apagó mientras se leía el GPS.');
    } on PermissionDeniedException {
      throw const FallaPermiso('Se retiró el permiso de ubicación.');
    }
  }

  Ubicacion _convertir(Position p) =>
      Ubicacion(latitud: p.latitude, longitud: p.longitude, precisionMetros: p.accuracy);
}
