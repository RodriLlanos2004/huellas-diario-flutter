import 'package:flutter/material.dart';

import '../../domain/entrada_diario.dart';

/// Cabecera de la lista con tres indicadores del diario.
class ResumenDiario extends StatelessWidget {
  const ResumenDiario({super.key, required this.entradas});
  final List<EntradaDiario> entradas;

  @override
  Widget build(BuildContext context) {
    final conFoto = entradas.where((e) => e.tieneImagen).length;
    final lugares = entradas.where((e) => e.tieneUbicacion).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          _Indicador(valor: entradas.length, etiqueta: 'entradas', icono: Icons.menu_book_outlined),
          const SizedBox(width: 8),
          _Indicador(valor: conFoto, etiqueta: 'con foto', icono: Icons.photo_outlined),
          const SizedBox(width: 8),
          _Indicador(valor: lugares, etiqueta: 'lugares', icono: Icons.place_outlined),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({required this.valor, required this.etiqueta, required this.icono});
  final int valor;
  final String etiqueta;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: tema.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icono, size: 20, color: tema.colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
            // Flexible + elipsis: con fuentes grandes de accesibilidad no se desborda.
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$valor',
                      style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
