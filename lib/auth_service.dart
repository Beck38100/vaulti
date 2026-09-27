import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Issue d'une demande d'authentification.
enum AuthOutcome {
  granted,

  /// L'utilisateur a fermé la fenêtre, ou le système l'a interrompue : rien
  /// d'anormal, il suffit de redemander.
  canceled,

  /// Le téléphone n'a ni code, ni schéma, ni empreinte : Android ne peut rien
  /// vérifier, et Vaulti refuse d'ouvrir un coffre que n'importe qui pourrait
  /// consulter en ramassant l'appareil.
  noDeviceLock,

  /// Trop d'essais ratés : Android bloque temporairement la vérification.
  lockedOut,

  unavailable,
}

/// Traduit une erreur de local_auth en issue compréhensible. Depuis la
/// version 3, une simple annulation est aussi signalée par une exception :
/// sans ce tri, fermer la fenêtre passerait pour une panne de l'appareil.
AuthOutcome outcomeForError(LocalAuthExceptionCode code) {
  switch (code) {
    case LocalAuthExceptionCode.userCanceled:
    case LocalAuthExceptionCode.systemCanceled:
    case LocalAuthExceptionCode.timeout:
    case LocalAuthExceptionCode.userRequestedFallback:
    case LocalAuthExceptionCode.authInProgress:
      return AuthOutcome.canceled;
    case LocalAuthExceptionCode.noCredentialsSet:
    case LocalAuthExceptionCode.noBiometricsEnrolled:
      return AuthOutcome.noDeviceLock;
    case LocalAuthExceptionCode.temporaryLockout:
    case LocalAuthExceptionCode.biometricLockout:
      return AuthOutcome.lockedOut;
    default:
      return AuthOutcome.unavailable;
  }
}

/// Résultat d'une demande d'authentification.
class AuthResult {
  const AuthResult(this.outcome);

  final AuthOutcome outcome;

  bool get granted => outcome == AuthOutcome.granted;

  /// Message à afficher, ou null quand il n'y a rien à dire : accès accordé,
  /// ou demande simplement annulée par l'utilisateur.
  String? get message {
    switch (outcome) {
      case AuthOutcome.granted:
      case AuthOutcome.canceled:
        return null;
      case AuthOutcome.noDeviceLock:
        return 'Pour protéger ton coffre, configure un code de verrouillage '
            '(PIN, schéma ou empreinte) sur ton téléphone.';
      case AuthOutcome.lockedOut:
        return 'Trop de tentatives. Patiente quelques instants avant de réessayer.';
      case AuthOutcome.unavailable:
        return 'Authentification indisponible sur cet appareil.';
    }
  }
}

/// Authentification biométrique (ou code de l'appareil).
///
/// Sur le Web il n'existe pas d'équivalent : l'accès est alors accordé
/// directement, ce qui permet de prévisualiser l'application au navigateur.
class AuthService {
  AuthService();

  final LocalAuthentication _auth = LocalAuthentication();

  static const _settingsChannel = MethodChannel('vaulti/device_settings');

  Future<AuthResult> authenticate(String reason) async {
    if (kIsWeb) return const AuthResult(AuthOutcome.granted);
    try {
      final granted = await _auth.authenticate(
        localizedReason: reason,
        // Sans cela, une notification qui met l'application en pause annule la
        // demande en cours et l'utilisateur croit à un refus.
        persistAcrossBackgrounding: true,
      );
      return AuthResult(granted ? AuthOutcome.granted : AuthOutcome.canceled);
    } on LocalAuthException catch (error) {
      return AuthResult(outcomeForError(error.code));
    } catch (_) {
      return const AuthResult(AuthOutcome.unavailable);
    }
  }

  /// Ouvre l'écran Android où l'on configure le verrouillage du téléphone.
  Future<void> openDeviceLockSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _settingsChannel.invokeMethod<void>('openSecuritySettings');
    } on PlatformException {
      // Rien de mieux à proposer : le message affiché explique déjà quoi faire.
    }
  }
}
