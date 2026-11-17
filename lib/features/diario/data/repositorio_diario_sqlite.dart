import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/errores.dart';
import '../domain/entrada_diario.dart';
import '../domain/repositorio_diario.dart';
import 'base_datos_diario.dart';

/// Implementación del repositorio con SQLite (`sqflite`).
class RepositorioDiarioSqlite implements RepositorioDiario {
  RepositorioDiarioSqlite(this._bd);

  final BaseDatosDiario _bd;
  static const _tabla = BaseDatosDiario.tablaEntradas;

  /// Ejecuta una operación y traduce los errores técnicos a [FallaAlmacenamiento].
  Future<T> _ejecutar<T>(String accion, Future<T> Function(Database db) operacion) async {
    try {
      return await operacion(await _bd.conexion);
    } on DatabaseException catch (e) {
      debugPrint('SQLite falló al $accion: $e');
      throw FallaAlmacenamiento('No se pudo $accion. Intenta de nuevo.', e);
    }
  }

  @override
  Future<List<EntradaDiario>> obtenerTodas() => _ejecutar('leer tu diario', (db) async {
        final filas = await db.query(_tabla, orderBy: 'fecha DESC, id DESC');
        final entradas = <EntradaDiario>[];
        for (final fila in filas) {
          // Un registro dañado no debe impedir que se vean los demás.
          try {
            entradas.add(EntradaDiario.fromMap(fila));
          } on Object catch (e) {
            debugPrint('Registro ${fila['id']} ignorado por estar dañado: $e');
          }
        }
        return entradas;
      });

  @override
  Future<EntradaDiario?> obtenerPorId(int id) => _ejecutar('leer la entrada', (db) async {
        final filas = await db.query(_tabla, where: 'id = ?', whereArgs: [id], limit: 1);
        return filas.isEmpty ? null : EntradaDiario.fromMap(filas.first);
      });

  @override
  Future<EntradaDiario> guardar(EntradaDiario entrada) => _ejecutar('guardar la entrada', (db) async {
        if (entrada.id == null) {
          final id = await db.insert(_tabla, entrada.toMap());
          return entrada.copyWith(id: id);
        }
        await db.update(_tabla, entrada.toMap(), where: 'id = ?', whereArgs: [entrada.id]);
        return entrada;
      });

  @override
  Future<void> eliminar(int id) => _ejecutar('eliminar la entrada', (db) async {
        await db.delete(_tabla, where: 'id = ?', whereArgs: [id]);
      });
}
