/// Estado de ánimo asociado a una entrada del diario.
///
/// La capa de dominio solo guarda el nombre y la etiqueta. El ícono y el
/// color se agregan en la capa de presentación (`animo_visual.dart`), para no
/// mezclar la lógica del negocio con detalles de la interfaz.
enum EstadoAnimo {
  radiante('Radiante'),
  feliz('Feliz'),
  tranquilo('Tranquilo'),
  cansado('Cansado'),
  triste('Triste');

  const EstadoAnimo(this.etiqueta);
  final String etiqueta;

  /// Convierte el texto guardado en SQLite o JSON; si no se reconoce, usa [tranquilo].
  static EstadoAnimo desdeNombre(String? nombre) =>
      values.firstWhere((e) => e.name == nombre, orElse: () => EstadoAnimo.tranquilo);
}
