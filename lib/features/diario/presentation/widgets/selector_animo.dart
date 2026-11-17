import 'package:flutter/material.dart';

import '../../domain/estado_animo.dart';
import 'animo_visual.dart';

/// Chips para elegir el estado de ánimo del día.
class SelectorAnimo extends StatelessWidget {
  const SelectorAnimo({super.key, required this.valor, required this.alCambiar});
  final EstadoAnimo valor;
  final ValueChanged<EstadoAnimo> alCambiar;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final a in EstadoAnimo.values)
            ChoiceChip(
              avatar: Icon(a.icono, color: a.color),
              label: Text(a.etiqueta),
              selected: a == valor,
              showCheckmark: false,
              onSelected: (_) => alCambiar(a),
            ),
        ],
      );
}
