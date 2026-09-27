import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:vaulti/auth_service.dart';

void main() {
  test('fermer la fenêtre d’authentification n’affiche aucun message', () {
    final outcome = outcomeForError(LocalAuthExceptionCode.userCanceled);

    expect(outcome, AuthOutcome.canceled);
    expect(AuthResult(outcome).message, isNull);
  });

  test('un téléphone sans verrouillage est reconnu comme tel', () {
    expect(outcomeForError(LocalAuthExceptionCode.noCredentialsSet), AuthOutcome.noDeviceLock);
    expect(outcomeForError(LocalAuthExceptionCode.noBiometricsEnrolled), AuthOutcome.noDeviceLock);
    expect(const AuthResult(AuthOutcome.noDeviceLock).message, contains('code de verrouillage'));
  });

  test('trop de tentatives demande de patienter', () {
    expect(outcomeForError(LocalAuthExceptionCode.temporaryLockout), AuthOutcome.lockedOut);
  });

  test('une erreur inconnue reste signalée comme indisponible', () {
    expect(outcomeForError(LocalAuthExceptionCode.deviceError), AuthOutcome.unavailable);
    expect(const AuthResult(AuthOutcome.unavailable).message, isNotNull);
  });
}
