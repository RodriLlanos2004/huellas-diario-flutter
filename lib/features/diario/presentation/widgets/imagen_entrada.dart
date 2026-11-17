import 'package:flutter/material.dart';

import '../../../../core/dependencias.dart';

/// Muestra la foto guardada de una entrada o un marcador si no tiene.
///
/// Se usa dentro de un Hero tanto en la lista como en el detalle, por eso el
/// mismo widget sabe dibujarse en miniatura y a pantalla completa.
class ImagenEntrada extends StatelessWidget {
  const ImagenEntrada({super.key, required this.nombre, this.radio = 0, this.miniatura = false});

  final String? nombre;
  final double radio;

  /// En miniatura se decodifica la imagen a menor resolución para ahorrar memoria.
  final bool miniatura;

  @override
  Widget build(BuildContext context) {
    final nombre = this.nombre;
    final Widget contenido;
    if (nombre == null) {
      contenido = const _SinImagen();
    } else {
      final archivo = AppScope.of(context).imagenesGuardadas.archivo(nombre);
      final escala = MediaQuery.devicePixelRatioOf(context);
      contenido = Image.file(
        archivo,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: miniatura ? (96 * escala).round() : null,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _SinImagen(rota: true),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radio), child: contenido);
  }
}

class _SinImagen extends StatelessWidget {
  const _SinImagen({this.rota = false});
  final bool rota;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [esquema.primaryContainer, esquema.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(rota ? Icons.broken_image_outlined : Icons.landscape_outlined,
            color: esquema.onPrimaryContainer, size: 32),
      ),
    );
  }
}
