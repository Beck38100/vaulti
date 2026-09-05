import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Contrôle la protection de l'écran côté Android (FLAG_SECURE).
///
/// Quand elle est active, le système refuse les captures d'écran et masque le
/// contenu du coffre dans l'aperçu des applications récentes — sans quoi
/// Android en enregistre une image sur le disque à chaque changement d'app.
///
/// Elle est activée dès le démarrage côté natif ; ce service sert à la couper
/// temporairement, par exemple pour prendre une capture d'écran.
class ScreenSecurity {
  const ScreenSecurity();

  static const _channel = MethodChannel('vaulti/screen_security');

  Future<void> setEnabled(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'enabled': enabled});
    } on PlatformException {
      // Fonction non disponible : on continue sans bloquer l'application.
    } on MissingPluginException {
      // Ancienne version installée sans le canal natif.
    }
  }
}
