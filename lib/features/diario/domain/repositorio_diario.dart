import 'entrada_diario.dart';

/// Contrato de acceso a las entradas del diario.
///
/// La interfaz de usuario depende de esta abstracción y no de SQLite
/// (principio de inversión de dependencias). Cualquier error de las
/// implementaciones se reporta como `FallaAlmacenamiento`.
abstract interface class RepositorioDiario {
  /// Todas las entradas, de la más reciente a la más antigua.
  Future<List<EntradaDiario>> obtenerTodas();

  Future<EntradaDiario?> obtenerPorId(int id);

  /// Inserta la entrada si no tiene id o la actualiza si ya existe.
  /// Devuelve la entrada con su id asignado.
  Future<EntradaDiario> guardar(EntradaDiario entrada);

  Future<void> eliminar(int id);
}
