import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/dependencias.dart';
import '../../../../core/errores.dart';
import '../../../../core/fechas.dart';
import '../../../../core/rutas.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/estados_vista.dart';
import '../../domain/entrada_diario.dart';
import '../widgets/animo_visual.dart';
import '../widgets/imagen_entrada.dart';
import '../widgets/mapa_osm.dart';

/// Mapa interactivo con todas las entradas que tienen ubicación.
class MapaRecuerdosPage extends StatefulWidget {
  const MapaRecuerdosPage({super.key});

  @override
  State<MapaRecuerdosPage> createState() => _MapaRecuerdosPageState();
}

class _MapaRecuerdosPageState extends State<MapaRecuerdosPage> {
  Future<List<EntradaDiario>>? _conUbicacion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _conUbicacion ??= _cargar();
  }

  Future<List<EntradaDiario>> _cargar() async {
    final todas = await AppScope.of(context).repositorio.obtenerTodas();
    return todas.where((e) => e.tieneUbicacion).toList();
  }

  void _mostrarResumen(EntradaDiario e) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 56,
                  height: 56,
                  child: ImagenEntrada(nombre: e.imagen, radio: 12, miniatura: true),
                ),
                title: Text(e.titulo),
                subtitle: Text('${Fechas.larga(e.fecha)}\n${e.animo.etiqueta}'),
                isThreeLine: true,
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(hoja);
                    Navigator.pushNamed(context, Rutas.detalle, arguments: e);
                  },
                  child: const Text('Ver entrada'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de recuerdos')),
      drawer: const AppDrawer(rutaActual: Rutas.mapa),
      body: FutureBuilder<List<EntradaDiario>>(
        future: _conUbicacion,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const EstadoCargando(mensaje: 'Ubicando tus recuerdos…');
          }
          if (snapshot.hasError) {
            return EstadoError(
              mensaje: mensajeDeError(snapshot.error),
              alReintentar: () => setState(() {
                _conUbicacion = _cargar();
              }),
            );
          }
          final entradas = snapshot.data!;
          if (entradas.isEmpty) {
            return const EstadoVacio(
              icono: Icons.travel_explore,
              titulo: 'Aún no hay lugares',
              mensaje: 'Las entradas que guardes con ubicación aparecerán aquí.',
            );
          }
          final puntos = [for (final e in entradas) MapaOsm.punto(e.ubicacion!)];
          return FlutterMap(
            options: MapOptions(
              initialCenter: puntos.first,
              initialZoom: 15,
              initialCameraFit: puntos.length > 1
                  ? CameraFit.coordinates(
                      coordinates: puntos,
                      padding: const EdgeInsets.all(64),
                      maxZoom: 16,
                    )
                  : null,
              interactionOptions: MapaOsm.interaccion,
            ),
            children: [
              MapaOsm.capaTeselas(),
              MarkerLayer(markers: [
                for (final e in entradas)
                  MapaOsm.marcador(
                    MapaOsm.punto(e.ubicacion!),
                    color: e.animo.color,
                    alTocar: () => _mostrarResumen(e),
                  ),
              ]),
              MapaOsm.atribucion(),
            ],
          );
        },
      ),
    );
  }
}
