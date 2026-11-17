import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Abre y crea la base de datos SQLite del diario.
///
/// Se abre una sola vez (perezosamente) y la misma conexión se reutiliza
/// en toda la app. En las pruebas se inyecta otra fábrica (FFI en memoria).
class BaseDatosDiario {
  BaseDatosDiario({DatabaseFactory? fabrica, String? ruta})
      : _fabrica = fabrica ?? databaseFactory,
        _rutaFija = ruta;

  static const nombreArchivo = 'huellas.db';
  static const version = 1;
  static const tablaEntradas = 'entradas';

  final DatabaseFactory _fabrica;
  final String? _rutaFija;
  Future<Database>? _apertura;

  /// Conexión abierta. Si dos llamadas llegan a la vez, ambas esperan la misma apertura.
  Future<Database> get conexion => _apertura ??= _abrir();

  Future<Database> _abrir() async {
    final ruta = _rutaFija ?? p.join(await _fabrica.getDatabasesPath(), nombreArchivo);
    return _fabrica.openDatabase(
      ruta,
      options: OpenDatabaseOptions(version: version, onCreate: _crear),
    );
  }

  static Future<void> _crear(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablaEntradas (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo      TEXT    NOT NULL,
        texto       TEXT    NOT NULL,
        fecha       INTEGER NOT NULL,
        animo       TEXT    NOT NULL,
        imagen      TEXT,
        latitud     REAL,
        longitud    REAL,
        precision_m REAL,
        metadatos   TEXT    NOT NULL DEFAULT '{}'
      )
    ''');
    await db.execute('CREATE INDEX idx_entradas_fecha ON $tablaEntradas(fecha DESC)');
  }

  Future<void> cerrar() async {
    final apertura = _apertura;
    _apertura = null;
    if (apertura != null) await (await apertura).close();
  }
}
