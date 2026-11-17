import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/errores.dart';
import '../../../core/fechas.dart';
import '../domain/entrada_diario.dart';
import '../domain/repositorio_diario.dart';

/// Resultado de una exportación.
class ResultadoRespaldo {
  const ResultadoRespaldo({required this.ruta, required this.total, required this.json});
  final String ruta;
  final int total;
  final String json;
}

/// Exporta el diario completo a un archivo JSON legible.
class ServicioRespaldo {
  ServicioRespaldo(this._repositorio, {Future<Directory> Function()? directorioBase})
      : _directorioBase = directorioBase ?? getApplicationDocumentsDirectory;

  final RepositorioDiario _repositorio;
  final Future<Directory> Function() _directorioBase;

  /// Convierte las entradas al formato del respaldo.
  static String serializar(List<EntradaDiario> entradas, DateTime momento) =>
      const JsonEncoder.withIndent('  ').convert({
        'app': 'Huellas',
        'formato': 1,
        'exportado': momento.toIso8601String(),
        'total': entradas.length,
        'entradas': [for (final e in entradas) e.toJson()],
      });

  /// Lee un respaldo y reconstruye las entradas. Lanza [FallaAlmacenamiento] si el archivo no es válido.
  static List<EntradaDiario> deserializar(String json) {
    try {
      final datos = jsonDecode(json) as Map<String, dynamic>;
      final lista = datos['entradas'] as List<dynamic>;
      return [for (final e in lista) EntradaDiario.fromJson(e as Map<String, dynamic>)];
    } on Object catch (e) {
      throw FallaAlmacenamiento('El archivo de respaldo no es válido.', e);
    }
  }

  Future<ResultadoRespaldo> exportar() async {
    final entradas = await _repositorio.obtenerTodas();
    final ahora = DateTime.now();
    final json = serializar(entradas, ahora);
    try {
      final carpeta = Directory(p.join((await _directorioBase()).path, 'respaldos'));
      await carpeta.create(recursive: true);
      final archivo = File(p.join(carpeta.path, 'huellas_${Fechas.sello(ahora)}.json'));
      await archivo.writeAsString(json, flush: true);
      return ResultadoRespaldo(ruta: archivo.path, total: entradas.length, json: json);
    } on FileSystemException catch (e) {
      throw FallaAlmacenamiento('No se pudo escribir el archivo de respaldo.', e);
    }
  }
}
