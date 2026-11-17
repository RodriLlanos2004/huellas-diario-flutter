import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/diario/domain/metadatos_entrada.dart';
import '../errores.dart';

/// Imagen elegida por el usuario, todavía en la carpeta temporal del sistema.
class ImagenSeleccionada {
  const ImagenSeleccionada(this.ruta, this.origen);
  final String ruta;
  final OrigenImagen origen;
}

/// Contrato para obtener una imagen de la cámara o de la galería.
abstract interface class ServicioImagenes {
  /// Devuelve null si el usuario cerró la cámara o la galería sin elegir.
  Future<ImagenSeleccionada?> seleccionar(OrigenImagen origen);

  /// En Android el sistema puede cerrar la app mientras la cámara está abierta.
  /// Este método recupera la foto tomada en ese caso.
  Future<ImagenSeleccionada?> recuperarPerdida();
}

class ServicioImagenesPicker implements ServicioImagenes {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<ImagenSeleccionada?> seleccionar(OrigenImagen origen) async {
    try {
      final archivo = await _picker.pickImage(
        source: origen == OrigenImagen.camara ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.rear,
        // Reducir la resolución ahorra espacio y memoria al mostrar la imagen.
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return archivo == null ? null : ImagenSeleccionada(archivo.path, origen);
    } on PlatformException catch (e) {
      throw switch (e.code) {
        'camera_access_denied' => const FallaPermiso(
            'Negaste el acceso a la cámara. Actívalo en los ajustes para tomar fotos.',
            permanente: true),
        'photo_access_denied' => const FallaPermiso(
            'Negaste el acceso a tus fotos. Actívalo en los ajustes para elegir una imagen.',
            permanente: true),
        'no_available_camera' => FallaHardware('Este dispositivo no tiene una cámara disponible.', e),
        _ => FallaHardware('No se pudo abrir la ${origen.etiqueta.toLowerCase()}.', e),
      };
    }
  }

  @override
  Future<ImagenSeleccionada?> recuperarPerdida() async {
    if (!Platform.isAndroid) return null;
    try {
      final respuesta = await _picker.retrieveLostData();
      final archivo = respuesta.file;
      if (respuesta.isEmpty || archivo == null) return null;
      return ImagenSeleccionada(archivo.path, OrigenImagen.camara);
    } on PlatformException {
      return null;
    }
  }
}
