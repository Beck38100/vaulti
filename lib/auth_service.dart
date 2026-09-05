import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Résultat d'une demande d'authentification.
class AuthResult {
  const AuthResult({required this.granted, this.error});

  final bool granted;

  /// Renseigné quand l'appareil n'a pas pu présenter la demande
  /// (pas de biométrie configurée, matériel indisponible...).
  final String? error;
}

/// Authentification biométrique (ou code de l'appareil).
///
/// Sur le Web il n'existe pas d'équivalent : l'accès est alors accordé
/// directement, ce qui permet de prévisualiser l'application au navigateur.
class AuthService {
  AuthService();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<AuthResult> authenticate(String reason) async {
    if (kIsWeb) return const AuthResult(granted: true);
    try {
      final granted = await _auth.authenticate(localizedReason: reason);
      return AuthResult(granted: granted);
    } catch (error) {
      return AuthResult(granted: false, error: error.toString());
    }
  }
}
