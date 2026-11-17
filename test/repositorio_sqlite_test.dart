import 'package:flutter_test/flutter_test.dart';
import 'package:huellas/features/diario/data/base_datos_diario.dart';
import 'package:huellas/features/diario/data/repositorio_diario_sqlite.dart';
import 'package:huellas/features/diario/domain/entrada_diario.dart';
import 'package:huellas/features/diario/domain/ubicacion.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Pruebas del repositorio contra un SQLite real en memoria (sqflite_common_ffi).
void main() {
  sqfliteFfiInit();
  late BaseDatosDiario bd;
  late RepositorioDiarioSqlite repo;

  setUp(() {
    bd = BaseDatosDiario(fabrica: databaseFactoryFfi, ruta: inMemoryDatabasePath);
    repo = RepositorioDiarioSqlite(bd);
  });

  tearDown(() => bd.cerrar());

  EntradaDiario entrada(String titulo, DateTime fecha, {Ubicacion? ubicacion}) =>
      EntradaDiario(titulo: titulo, texto: 'texto de $titulo', fecha: fecha, ubicacion: ubicacion);

  test('guardar asigna id y la entrada se puede leer de nuevo', () async {
    final guardada = await repo.guardar(entrada('Uno', DateTime(2026, 11, 1),
        ubicacion: const Ubicacion(latitud: 21.0, longitud: -89.6)));
    expect(guardada.id, isNotNull);
    final leida = await repo.obtenerPorId(guardada.id!);
    expect(leida?.titulo, 'Uno');
    expect(leida?.ubicacion?.latitud, 21.0);
  });

  test('obtenerTodas ordena de la más reciente a la más antigua', () async {
    await repo.guardar(entrada('Vieja', DateTime(2026, 1, 1)));
    await repo.guardar(entrada('Nueva', DateTime(2026, 11, 1)));
    final todas = await repo.obtenerTodas();
    expect(todas.map((e) => e.titulo), ['Nueva', 'Vieja']);
  });

  test('guardar con id existente actualiza en lugar de duplicar', () async {
    final g = await repo.guardar(entrada('Original', DateTime(2026)));
    await repo.guardar(g.copyWith(titulo: 'Editada'));
    final todas = await repo.obtenerTodas();
    expect(todas, hasLength(1));
    expect(todas.single.titulo, 'Editada');
  });

  test('eliminar borra la entrada', () async {
    final g = await repo.guardar(entrada('Borrar', DateTime(2026)));
    await repo.eliminar(g.id!);
    expect(await repo.obtenerTodas(), isEmpty);
  });

  test('un registro dañado se ignora sin perder los demás', () async {
    await repo.guardar(entrada('Sana', DateTime(2026)));
    final db = await bd.conexion;
    // Fecha guardada como texto: fromMap fallará al convertirla.
    await db.insert(BaseDatosDiario.tablaEntradas,
        {'titulo': 'Dañada', 'texto': 'x', 'fecha': 'no-es-fecha', 'animo': 'feliz'});
    final todas = await repo.obtenerTodas();
    expect(todas.map((e) => e.titulo), ['Sana']);
  });
}
