import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errores.dart';

/// Guarda las fotos del diario en la carpeta privada de documentos de la app.
///
/// La cámara y la galería entregan archivos temporales que el sistema puede
/// borrar en cualquier momento; por eso cada imagen se copia aquí antes de
/// registrar su nombre en SQLite.
class AlmacenImagenes {
  AlmacenImagenes({Future<Directory> Function()? directorioBase})
      : _directorioBase = directorioBase ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directorioBase;
  Directory? _carpeta;

  /// Se llama una vez al iniciar la app (en `main`).
  Future<void> inicializar() async {
    final base = await _directorioBase();
    final carpeta = Directory(p.join(base.path, 'imagenes'));
    await carpeta.create(recursive: true);
    _carpeta = carpeta;
  }

  Directory get _lista {
    final carpeta = _carpeta;
    if (carpeta == null) throw StateError('AlmacenImagenes no fue inicializado');
    return carpeta;
  }

  /// Archivo correspondiente a un nombre guardado en la base de datos.
  File archivo(String nombre) => File(p.join(_lista.path, nombre));

  /// Copia la imagen temporal y devuelve el nombre con el que quedó guardada.
  Future<String> guardarCopia(String rutaTemporal) async {
    final extension = p.extension(rutaTemporal).toLowerCase();
    final nombre =
        'huella_${DateTime.now().millisecondsSinceEpoch}${extension.isEmpty ? '.jpg' : extension}';
    try {
      await File(rutaTemporal).copy(archivo(nombre).path);
      return nombre;
    } on FileSystemException catch (e) {
      throw FallaAlmacenamiento('No se pudo guardar la foto en el dispositivo.', e);
    }
  }

  /// Borra una imagen; si falla solo se registra, no interrumpe al usuario.
  Future<void> eliminar(String? nombre) async {
    if (nombre == null) return;
    try {
      final f = archivo(nombre);
      if (await f.exists()) await f.delete();
    } on FileSystemException catch (e) {
      debugPrint('No se pudo borrar la imagen $nombre: $e');
    }
  }
}
