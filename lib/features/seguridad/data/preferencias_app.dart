import 'package:shared_preferences/shared_preferences.dart';

/// Ajustes sencillos de la app. Se guardan con SharedPreferences porque son
/// pares clave-valor; los registros del diario van en SQLite.
abstract interface class PreferenciasApp {
  bool get bloqueoActivo;
  Future<void> guardarBloqueoActivo(bool activo);

  DateTime? get ultimoRespaldo;
  Future<void> guardarUltimoRespaldo(DateTime momento);
}

class PreferenciasCompartidas implements PreferenciasApp {
  PreferenciasCompartidas._(this._prefs);

  static const _kBloqueo = 'bloqueo_activo';
  static const _kRespaldo = 'ultimo_respaldo';

  final SharedPreferencesWithCache _prefs;

  static Future<PreferenciasCompartidas> cargar() async => PreferenciasCompartidas._(
        await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(allowList: {_kBloqueo, _kRespaldo}),
        ),
      );

  /// Por seguridad, el bloqueo viene activado de fábrica.
  @override
  bool get bloqueoActivo => _prefs.getBool(_kBloqueo) ?? true;

  @override
  Future<void> guardarBloqueoActivo(bool activo) => _prefs.setBool(_kBloqueo, activo);

  @override
  DateTime? get ultimoRespaldo {
    final ms = _prefs.getInt(_kRespaldo);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> guardarUltimoRespaldo(DateTime momento) =>
      _prefs.setInt(_kRespaldo, momento.millisecondsSinceEpoch);
}
