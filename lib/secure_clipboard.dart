import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Copie d'un mot de passe dans le presse-papiers, côté Android.
///
/// `Clipboard.setData` ne marque pas le contenu comme sensible : Android 13 et
/// suivants affichent alors le mot de passe en clair dans l'aperçu du
/// presse-papiers, et les claviers le conservent dans leur historique — ce qui
/// annulerait l'effet de FLAG_SECURE. Le canal natif pose le drapeau qui
/// l'en empêche, et vide le presse-papiers sans avoir à le relire.
class SecureClipboard {
  const SecureClipboard();

  static const _channel = MethodChannel('vaulti/secure_clipboard');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Copie [text] en le signalant comme sensible quand la plateforme le permet.
  Future<void> copy(String text) async {
    if (_isAndroid) {
      try {
        await _channel.invokeMethod<void>('copy', {'text': text});
        return;
      } on PlatformException {
        // Copie impossible côté natif : on retombe sur le presse-papiers de
        // Flutter, sans le drapeau, plutôt que de ne rien copier du tout.
      } on MissingPluginException {
        // Ancienne version installée sans le canal natif.
      }
    }
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Vide le presse-papiers s'il contient encore une copie faite par Vaulti.
  ///
  /// Renvoie faux si l'utilisateur a copié autre chose entre-temps : son
  /// contenu à lui ne doit pas être effacé. Le côté natif reconnaît ses propres
  /// copies à leur libellé, sans lire le contenu : relire le presse-papiers
  /// d'une autre application déclencherait une notification système inutile.
  Future<bool> clearIfOurs() async {
    if (_isAndroid) {
      try {
        return await _channel.invokeMethod<bool>('clearIfOurs') ?? false;
      } on PlatformException {
        // Voir ci-dessous : on tente quand même la voie Flutter.
      } on MissingPluginException {
        // Idem.
      }
    }
    await Clipboard.setData(const ClipboardData(text: ''));
    return true;
  }
}
