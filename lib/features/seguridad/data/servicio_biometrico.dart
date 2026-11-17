import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// Qué puede usar el dispositivo para verificar al usuario.
enum DisponibilidadBiometrica {
  /// Huella o rostro registrados.
  biometria,

  /// Sin biometría registrada, pero con PIN, patrón o contraseña.
  soloCredencial,

  /// El dispositivo no tiene ningún bloqueo configurado.
  ninguna,
}

enum ResultadoAutenticacion { exito, cancelado, bloqueadoTemporal, noDisponible, error }

/// Contrato para el inicio de sesión biométrico.
abstract interface class ServicioBiometrico {
  Future<DisponibilidadBiometrica> disponibilidad();
  Future<ResultadoAutenticacion> autenticar(String motivo);
}

/// Implementación con `local_auth` (BiometricPrompt en Android, Face ID / Touch ID en iOS).
///
/// La verificación ocurre en el hardware seguro del sistema operativo: la app
/// nunca recibe la huella ni el PIN, solo un resultado verdadero o falso.
class ServicioBiometricoLocalAuth implements ServicioBiometrico {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<DisponibilidadBiometrica> disponibilidad() async {
    try {
      if (!await _auth.isDeviceSupported()) return DisponibilidadBiometrica.ninguna;
      final registradas = await _auth.getAvailableBiometrics();
      return registradas.isNotEmpty
          ? DisponibilidadBiometrica.biometria
          : DisponibilidadBiometrica.soloCredencial;
    } on PlatformException {
      return DisponibilidadBiometrica.ninguna;
    } on LocalAuthException {
      return DisponibilidadBiometrica.ninguna;
    }
  }

  @override
  Future<ResultadoAutenticacion> autenticar(String motivo) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: motivo,
        // Se permite el PIN del dispositivo como respaldo si la huella falla.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Desbloquear Huellas',
            signInHint: 'Toca el sensor de huella',
            cancelButton: 'Cancelar',
          ),
        ],
      );
      return ok ? ResultadoAutenticacion.exito : ResultadoAutenticacion.cancelado;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          ResultadoAutenticacion.cancelado,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          ResultadoAutenticacion.bloqueadoTemporal,
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware =>
          ResultadoAutenticacion.noDisponible,
        _ => ResultadoAutenticacion.error,
      };
    } on PlatformException {
      return ResultadoAutenticacion.error;
    }
  }
}
