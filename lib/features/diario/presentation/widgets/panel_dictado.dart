import 'package:flutter/material.dart';

/// Retroalimentación visual del dictado: barras que reaccionan al nivel de
/// sonido que captura el micrófono y el texto parcial reconocido.
class PanelDictado extends StatelessWidget {
  const PanelDictado({
    super.key,
    required this.nivel,
    required this.textoParcial,
    required this.alDetener,
  });

  /// Nivel de sonido reportado por el reconocedor (aprox. -2 a 10 dB en Android).
  final double nivel;
  final String textoParcial;
  final VoidCallback alDetener;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final normalizado = ((nivel + 2) / 12).clamp(0.0, 1.0);
    return Card(
      color: tema.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 44 + 16 * normalizado,
              height: 44 + 16 * normalizado,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tema.colorScheme.tertiary.withValues(alpha: 0.25 + 0.5 * normalizado),
              ),
              child: Icon(Icons.mic, color: tema.colorScheme.onTertiaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Escuchando…',
                          style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _Barras(normalizado: normalizado, color: tema.colorScheme.tertiary),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    textoParcial.isEmpty ? 'Habla con naturalidad; el texto aparece abajo.' : textoParcial,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: alDetener, child: const Text('Listo')),
          ],
        ),
      ),
    );
  }
}

class _Barras extends StatelessWidget {
  const _Barras({required this.normalizado, required this.color});
  final double normalizado;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const pesos = [0.5, 0.8, 1.0, 0.7, 0.4];
    return Row(
      children: [
        for (final p in pesos)
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 4,
            height: 4 + 14 * normalizado * p,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
      ],
    );
  }
}
