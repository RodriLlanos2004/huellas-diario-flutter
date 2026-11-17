/// Formato de fechas en español sin depender de paquetes externos.
abstract final class Fechas {
  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];
  static const _dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];

  static String _dos(int n) => n.toString().padLeft(2, '0');

  /// "martes 17 de noviembre de 2026"
  static String larga(DateTime f) =>
      '${_dias[f.weekday - 1]} ${f.day} de ${_meses[f.month - 1]} de ${f.year}';

  /// "17 nov 2026"
  static String corta(DateTime f) =>
      '${f.day} ${_meses[f.month - 1].substring(0, 3)} ${f.year}';

  /// "08:05"
  static String hora(DateTime f) => '${_dos(f.hour)}:${_dos(f.minute)}';

  /// "20261117_080512", para nombres de archivo.
  static String sello(DateTime f) =>
      '${f.year}${_dos(f.month)}${_dos(f.day)}_${_dos(f.hour)}${_dos(f.minute)}${_dos(f.second)}';
}
