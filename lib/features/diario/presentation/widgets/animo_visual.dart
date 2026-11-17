import 'package:flutter/material.dart';

import '../../domain/estado_animo.dart';

/// Ícono y color de cada estado de ánimo (detalle exclusivo de la interfaz).
extension AnimoVisual on EstadoAnimo {
  IconData get icono => switch (this) {
        EstadoAnimo.radiante => Icons.sentiment_very_satisfied,
        EstadoAnimo.feliz => Icons.sentiment_satisfied_alt,
        EstadoAnimo.tranquilo => Icons.spa_outlined,
        EstadoAnimo.cansado => Icons.bedtime_outlined,
        EstadoAnimo.triste => Icons.sentiment_dissatisfied,
      };

  Color get color => switch (this) {
        EstadoAnimo.radiante => const Color(0xFFF9A825),
        EstadoAnimo.feliz => const Color(0xFF43A047),
        EstadoAnimo.tranquilo => const Color(0xFF00897B),
        EstadoAnimo.cansado => const Color(0xFF7E57C2),
        EstadoAnimo.triste => const Color(0xFF1E88E5),
      };
}
