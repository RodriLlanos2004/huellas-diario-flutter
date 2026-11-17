import 'package:flutter/material.dart';

import '../../domain/metadatos_entrada.dart';

/// Acción elegida en la hoja inferior de la imagen.
enum AccionImagen {
  camara(OrigenImagen.camara),
  galeria(OrigenImagen.galeria),
  quitar(null);

  const AccionImagen(this.origen);

  /// Origen correspondiente; null cuando se pidió quitar la imagen.
  final OrigenImagen? origen;
}

/// Muestra la hoja inferior para elegir entre cámara y galería.
Future<AccionImagen?> mostrarHojaOrigenImagen(BuildContext context, {required bool tieneImagen}) =>
    showModalBottomSheet<AccionImagen>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Ilustra tu día')),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto con la cámara'),
              onTap: () => Navigator.pop(context, AccionImagen.camara),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, AccionImagen.galeria),
            ),
            if (tieneImagen)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Quitar imagen'),
                onTap: () => Navigator.pop(context, AccionImagen.quitar),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
