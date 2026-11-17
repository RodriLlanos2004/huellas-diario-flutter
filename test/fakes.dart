import 'dart:io';

import 'package:huellas/core/dependencias.dart';
import 'package:huellas/core/dispositivo/servicio_dictado.dart';
import 'package:huellas/core/dispositivo/servicio_imagenes.dart';
import 'package:huellas/core/dispositivo/servicio_mapas_externos.dart';
import 'package:huellas/core/dispositivo/servicio_permisos.dart';
import 'package:huellas/core/dispositivo/servicio_ubicacion.dart';
import 'package:huellas/core/errores.dart';
import 'package:huellas/features/diario/data/almacen_imagenes.dart';
import 'package:huellas/features/diario/data/servicio_respaldo.dart';
import 'package:huellas/features/diario/domain/entrada_diario.dart';
import 'package:huellas/features/diario/domain/metadatos_entrada.dart';
import 'package:huellas/features/diario/domain/repositorio_diario.dart';
import 'package:huellas/features/diario/domain/ubicacion.dart';
import 'package:huellas/features/seguridad/data/preferencias_app.dart';
import 'package:huellas/features/seguridad/data/servicio_biometrico.dart';

/// Repositorio en memoria. Si [fallar] es true, simula un error de SQLite.
class RepositorioFalso implements RepositorioDiario {
  RepositorioFalso([List<EntradaDiario>? iniciales]) : entradas = [...?iniciales];
  final List<EntradaDiario> entradas;
  bool fallar = false;
  int _siguienteId = 100;

  void _quizaFallar() {
    if (fallar) throw const FallaAlmacenamiento('No se pudo leer tu diario. Intenta de nuevo.');
  }

  @override
  Future<List<EntradaDiario>> obtenerTodas() async {
    _quizaFallar();
    return [...entradas]..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Future<EntradaDiario?> obtenerPorId(int id) async =>
      entradas.where((e) => e.id == id).firstOrNull;

  @override
  Future<EntradaDiario> guardar(EntradaDiario entrada) async {
    _quizaFallar();
    final guardada = entrada.copyWith(id: entrada.id ?? _siguienteId++);
    entradas.add(guardada);
    return guardada;
  }

  @override
  Future<void> eliminar(int id) async => entradas.removeWhere((e) => e.id == id);
}

class PreferenciasEnMemoria implements PreferenciasApp {
  @override
  bool bloqueoActivo = false;
  @override
  DateTime? ultimoRespaldo;
  @override
  Future<void> guardarBloqueoActivo(bool activo) async => bloqueoActivo = activo;
  @override
  Future<void> guardarUltimoRespaldo(DateTime momento) async => ultimoRespaldo = momento;
}

class BiometriaFalsa implements ServicioBiometrico {
  BiometriaFalsa({this.resultado = ResultadoAutenticacion.exito});
  ResultadoAutenticacion resultado;
  int intentos = 0;
  @override
  Future<DisponibilidadBiometrica> disponibilidad() async => DisponibilidadBiometrica.biometria;
  @override
  Future<ResultadoAutenticacion> autenticar(String motivo) async {
    intentos++;
    return resultado;
  }
}

class UbicacionFalsa implements ServicioUbicacion {
  FallaApp? falla;
  Ubicacion valor = const Ubicacion(latitud: 21.0419, longitud: -89.6211, precisionMetros: 8);
  @override
  Future<Ubicacion> obtenerActual({Duration limite = const Duration(seconds: 12)}) async {
    final f = falla;
    if (f != null) throw f;
    return valor;
  }
}

class DictadoFalso implements ServicioDictado {
  FallaApp? fallaAlPreparar;
  String frase = 'Hoy fue un gran día';
  @override
  bool escuchando = false;
  @override
  Future<void> preparar() async {
    final f = fallaAlPreparar;
    if (f != null) throw f;
  }

  @override
  Future<void> escuchar({
    required void Function(String texto, bool esFinal) alReconocer,
    required void Function() alTerminar,
    required void Function(String mensaje) alFallar,
    void Function(double nivel)? alCambiarNivel,
  }) async {
    escuchando = true;
    alCambiarNivel?.call(6);
    alReconocer(frase, true);
    escuchando = false;
    alTerminar();
  }

  @override
  Future<void> detener() async => escuchando = false;
  @override
  Future<void> cancelar() async => escuchando = false;
}

class ImagenesFalsas implements ServicioImagenes {
  @override
  Future<ImagenSeleccionada?> seleccionar(OrigenImagen origen) async => null;
  @override
  Future<ImagenSeleccionada?> recuperarPerdida() async => null;
}

class MapasFalsos implements ServicioMapasExternos {
  Ubicacion? abierta;
  @override
  Future<bool> abrir(Ubicacion ubicacion) async {
    abierta = ubicacion;
    return true;
  }
}

class PermisosFalsos implements ServicioPermisos {
  int aperturas = 0;
  @override
  Future<bool> abrirAjustesApp() async => ++aperturas > 0;
  @override
  Future<bool> abrirAjustesUbicacion() async => ++aperturas > 0;
}

/// Construye un contenedor de dependencias completamente falso.
Dependencias dependenciasFalsas({
  RepositorioFalso? repositorio,
  UbicacionFalsa? ubicacion,
  DictadoFalso? dictado,
  BiometriaFalsa? biometria,
  PreferenciasEnMemoria? preferencias,
}) {
  final repo = repositorio ?? RepositorioFalso();
  return Dependencias(
    repositorio: repo,
    imagenesGuardadas: AlmacenImagenes(directorioBase: () async => Directory.systemTemp),
    respaldo: ServicioRespaldo(repo, directorioBase: () async => Directory.systemTemp),
    preferencias: preferencias ?? PreferenciasEnMemoria(),
    biometria: biometria ?? BiometriaFalsa(),
    ubicacion: ubicacion ?? UbicacionFalsa(),
    dictado: dictado ?? DictadoFalso(),
    imagenes: ImagenesFalsas(),
    mapas: MapasFalsos(),
    permisos: PermisosFalsos(),
  );
}

EntradaDiario entradaDeEjemplo({int id = 1, String titulo = 'Paseo por Paseo de Montejo'}) =>
    EntradaDiario(
      id: id,
      titulo: titulo,
      texto: 'Caminé con mis amigos y probamos marquesitas.',
      fecha: DateTime(2026, 11, 10 + id, 18, 30),
      ubicacion: const Ubicacion(latitud: 20.9802, longitud: -89.6196, precisionMetros: 12),
      metadatos: const MetadatosEntrada(usoDictado: true, segundosDictado: 7),
    );
