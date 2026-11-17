import 'package:flutter/material.dart';

import '../../../core/dependencias.dart';
import '../../../core/errores.dart';
import '../../../core/fechas.dart';
import '../../../core/rutas.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../seguridad/data/servicio_biometrico.dart';

/// Ajustes: bloqueo biométrico, respaldo JSON y permisos.
class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  late final Dependencias _dep = AppScope.of(context);
  bool _exportando = false;

  void _avisar(String mensaje) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));

  /// Cambiar el bloqueo exige autenticarse: así nadie lo desactiva con el teléfono ajeno.
  Future<void> _cambiarBloqueo(bool activar) async {
    if (activar &&
        await _dep.biometria.disponibilidad() == DisponibilidadBiometrica.ninguna) {
      _avisar('Configura una huella o un PIN en el dispositivo para activar el bloqueo.');
      return;
    }
    final resultado = await _dep.biometria.autenticar(
        activar ? 'Confirma para activar el bloqueo' : 'Confirma para desactivar el bloqueo');
    if (!mounted) return;
    if (resultado != ResultadoAutenticacion.exito) {
      _avisar('No se cambió el ajuste porque no se completó la autenticación.');
      return;
    }
    await _dep.preferencias.guardarBloqueoActivo(activar);
    if (mounted) setState(() {});
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final r = await _dep.respaldo.exportar();
      await _dep.preferencias.guardarUltimoRespaldo(DateTime.now());
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.data_object),
          title: Text('Respaldo creado (${r.total} entradas)'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SelectableText(r.ruta, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      r.json.length > 900 ? '${r.json.substring(0, 900)}\n…' : r.json,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Listo')),
          ],
        ),
      );
    } on FallaApp catch (f) {
      if (mounted) _avisar(f.mensaje);
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ultimo = _dep.preferencias.ultimoRespaldo;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      drawer: const AppDrawer(rutaActual: Rutas.ajustes),
      body: ListView(
        children: [
          const _Seccion('Seguridad'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Bloqueo con huella o PIN'),
            subtitle: const Text('Al abrir la app y al volver después de 1 minuto'),
            value: _dep.preferencias.bloqueoActivo,
            onChanged: _cambiarBloqueo,
          ),
          const _Seccion('Datos'),
          ListTile(
            leading: const Icon(Icons.data_object),
            title: const Text('Exportar respaldo JSON'),
            subtitle: Text(ultimo == null
                ? 'Aún no has creado un respaldo'
                : 'Último: ${Fechas.corta(ultimo)}, ${Fechas.hora(ultimo)}'),
            trailing: _exportando
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _exportando ? null : _exportar,
          ),
          const _Seccion('Permisos'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Permisos de cámara, micrófono y ubicación'),
            subtitle: const Text('Abrir los ajustes del sistema para esta app'),
            onTap: () => _dep.permisos.abrirAjustesApp(),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Huellas',
            applicationVersion: '1.0.0',
            applicationIcon: Icon(Icons.fingerprint, size: 40),
            aboutBoxChildren: [
              Text('Diario personal con foto, dictado por voz y ubicación GPS.\n\n'
                  'Proyecto de Programación de Dispositivos Móviles, Universidad Anáhuac Mayab.'),
            ],
            child: Text('Acerca de Huellas'),
          ),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(titulo,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
