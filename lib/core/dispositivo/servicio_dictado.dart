import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../errores.dart';

/// Contrato para dictar texto con el micrófono.
abstract interface class ServicioDictado {
  bool get escuchando;

  /// Verifica el permiso de micrófono e inicializa el reconocedor.
  /// Lanza [FallaPermiso] o [FallaHardware].
  Future<void> preparar();

  /// Abre el micrófono y empieza a reconocer voz.
  Future<void> escuchar({
    required void Function(String texto, bool esFinal) alReconocer,
    required void Function() alTerminar,
    required void Function(String mensaje) alFallar,
    void Function(double nivel)? alCambiarNivel,
  });

  Future<void> detener();
  Future<void> cancelar();
}

/// Implementación con `speech_to_text`, que usa el reconocedor del sistema
/// (SpeechRecognizer en Android, SFSpeechRecognizer en iOS). El paquete
/// captura el audio del micrófono y entrega el texto parcial y final.
class ServicioDictadoSpeech implements ServicioDictado {
  final SpeechToText _voz = SpeechToText();
  bool _inicializado = false;
  String? _idioma;

  void Function()? _alTerminar;
  void Function(String)? _alFallar;

  @override
  bool get escuchando => _voz.isListening;

  @override
  Future<void> preparar() async {
    // Se pide el permiso con permission_handler para distinguir una negación
    // simple de una permanente y poder ofrecer "Abrir ajustes".
    final estado = await Permission.microphone.request();
    if (estado.isPermanentlyDenied || estado.isRestricted) {
      throw const FallaPermiso(
          'El micrófono está bloqueado para Huellas. Actívalo en los ajustes para dictar.',
          permanente: true);
    }
    if (!estado.isGranted) {
      throw const FallaPermiso('Necesito el micrófono para convertir tu voz en texto.');
    }
    if (_inicializado) return;

    try {
      _inicializado = await _voz.initialize(onError: _manejarError, onStatus: _manejarEstado);
    } on PlatformException catch (e) {
      throw FallaHardware('El reconocimiento de voz no está disponible.', e);
    }
    if (!_inicializado) {
      throw const FallaHardware('Este dispositivo no tiene un servicio de reconocimiento de voz.');
    }
    _idioma = await _elegirIdiomaEspanol();
  }

  /// Prefiere español de México; si no existe, cualquier variante de español.
  Future<String?> _elegirIdiomaEspanol() async {
    try {
      final idiomas = await _voz.locales();
      String? buscar(bool Function(String id) criterio) {
        for (final l in idiomas) {
          if (criterio(l.localeId.toLowerCase())) return l.localeId;
        }
        return null;
      }

      return buscar((id) => id == 'es_mx' || id == 'es-mx') ?? buscar((id) => id.startsWith('es'));
    } on PlatformException {
      return null; // Se usará el idioma del sistema.
    }
  }

  @override
  Future<void> escuchar({
    required void Function(String texto, bool esFinal) alReconocer,
    required void Function() alTerminar,
    required void Function(String mensaje) alFallar,
    void Function(double nivel)? alCambiarNivel,
  }) async {
    if (!_inicializado) await preparar();
    _alTerminar = alTerminar;
    _alFallar = alFallar;
    try {
      await _voz.listen(
        onResult: (r) => alReconocer(r.recognizedWords, r.finalResult),
        onSoundLevelChange: alCambiarNivel,
        listenOptions: SpeechListenOptions(
          localeId: _idioma,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 5),
        ),
      );
    } on PlatformException catch (e) {
      _finalizar();
      alFallar('No se pudo abrir el micrófono: ${e.message ?? e.code}');
    }
  }

  void _manejarEstado(String estado) {
    if (estado == SpeechToText.doneStatus || estado == SpeechToText.notListeningStatus) {
      _finalizar();
    }
  }

  void _manejarError(SpeechRecognitionError error) {
    _alFallar?.call(_traducir(error.errorMsg));
    _finalizar();
  }

  void _finalizar() {
    final callback = _alTerminar;
    _alTerminar = null;
    callback?.call();
  }

  String _traducir(String codigo) => switch (codigo) {
        'error_no_match' => 'No entendí lo que dijiste. Habla un poco más cerca del micrófono.',
        'error_speech_timeout' => 'No escuché nada. Toca el micrófono e intenta de nuevo.',
        'error_network' || 'error_network_timeout' || 'error_server_disconnected' =>
          'El dictado necesita conexión a internet en este dispositivo.',
        'error_audio' => 'Hubo un problema al capturar el audio del micrófono.',
        'error_permission' || 'error_insufficient_permissions' =>
          'El micrófono no tiene permiso para grabar.',
        'error_busy' || 'error_recognizer_busy' => 'El reconocedor de voz está ocupado. Intenta de nuevo.',
        _ => 'El dictado se detuvo ($codigo).',
      };

  @override
  Future<void> detener() => _voz.stop();

  @override
  Future<void> cancelar() async {
    _alTerminar = null;
    _alFallar = null;
    await _voz.cancel();
  }
}
