import 'package:flutter/material.dart';

import '../../../../core/dependencias.dart';
import '../../../../core/errores.dart';
import '../../../../core/rutas.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/estados_vista.dart';
import '../../domain/entrada_diario.dart';
import '../widgets/resumen_diario.dart';
import '../widgets/tarjeta_entrada.dart';

/// Pantalla principal: lista de entradas cargadas de SQLite con FutureBuilder.
class ListaDiarioPage extends StatefulWidget {
  const ListaDiarioPage({super.key});

  @override
  State<ListaDiarioPage> createState() => _ListaDiarioPageState();
}

class _ListaDiarioPageState extends State<ListaDiarioPage> with RouteAware {
  // El Future se guarda en el estado: si se creara dentro de build(),
  // cada reconstrucción volvería a consultar la base de datos.
  Future<List<EntradaDiario>>? _entradas;
  ModalRoute<void>? _ruta;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entradas ??= _cargar();
    final ruta = ModalRoute.of(context);
    if (ruta != null && ruta != _ruta) {
      _ruta = ruta;
      observadorRutas.subscribe(this, ruta);
    }
  }

  @override
  void dispose() {
    observadorRutas.unsubscribe(this);
    super.dispose();
  }

  /// Se ejecuta al volver a esta pantalla desde otra (detalle, formulario, mapa…).
  @override
  void didPopNext() => _recargar();

  Future<List<EntradaDiario>> _cargar() => AppScope.of(context).repositorio.obtenerTodas();

  void _recargar() {
    setState(() {
      _entradas = _cargar();
    });
  }

  Future<void> _nuevaEntrada() async {
    // Sin parámetro de tipo: el generador de rutas crea MaterialPageRoute<dynamic>.
    final guardada = await Navigator.pushNamed(context, Rutas.nueva);
    if (guardada == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada guardada en tu diario')),
      );
    }
  }

  Future<void> _abrir(EntradaDiario entrada) async {
    final eliminada = await Navigator.pushNamed(context, Rutas.detalle, arguments: entrada);
    if (eliminada == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se eliminó "${entrada.titulo}"')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis huellas'),
        actions: [
          IconButton(
            tooltip: 'Mapa de recuerdos',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.pushNamed(context, Rutas.mapa),
          ),
        ],
      ),
      drawer: const AppDrawer(rutaActual: Rutas.lista),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaEntrada,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Nueva entrada'),
      ),
      body: FutureBuilder<List<EntradaDiario>>(
        future: _entradas,
        builder: (context, snapshot) {
          // Primera carga: indicador de progreso.
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const EstadoCargando(mensaje: 'Cargando tu diario…');
          }
          if (snapshot.hasError) {
            return EstadoError(mensaje: mensajeDeError(snapshot.error), alReintentar: _recargar);
          }
          final entradas = snapshot.data ?? const <EntradaDiario>[];
          if (entradas.isEmpty) {
            return EstadoVacio(
              icono: Icons.auto_stories_outlined,
              titulo: 'Tu diario está vacío',
              mensaje: 'Registra tu primer día con una foto, tu voz y el lugar donde estás.',
              accion: FilledButton.icon(
                onPressed: _nuevaEntrada,
                icon: const Icon(Icons.add),
                label: const Text('Escribir mi primera entrada'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _recargar();
              try {
                await _entradas;
              } on FallaApp {
                // El error ya se muestra en la vista; aquí solo se cierra el indicador.
              }
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: entradas.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => i == 0
                  ? ResumenDiario(entradas: entradas)
                  : TarjetaEntrada(
                      entrada: entradas[i - 1],
                      alTocar: () => _abrir(entradas[i - 1]),
                    ),
            ),
          );
        },
      ),
    );
  }
}
