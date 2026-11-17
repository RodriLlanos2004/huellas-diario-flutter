import 'package:flutter/material.dart';

/// Indicador de carga con mensaje, usado mientras un FutureBuilder espera.
class EstadoCargando extends StatelessWidget {
  const EstadoCargando({super.key, required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(mensaje, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
}

/// Pantalla para listas vacías, con una acción sugerida.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: tema.colorScheme.primaryContainer,
              child: Icon(icono, size: 48, color: tema.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(titulo, style: tema.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(mensaje,
                style: tema.textTheme.bodyMedium
                    ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            if (accion != null) ...[const SizedBox(height: 20), accion!],
          ],
        ),
      ),
    );
  }
}

/// Pantalla de error con botón para reintentar. Evita que un fallo deje la vista en blanco.
class EstadoError extends StatelessWidget {
  const EstadoError({super.key, required this.mensaje, required this.alReintentar});
  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) => EstadoVacio(
        icono: Icons.error_outline,
        titulo: 'Algo salió mal',
        mensaje: mensaje,
        accion: FilledButton.icon(
          onPressed: alReintentar,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
}
