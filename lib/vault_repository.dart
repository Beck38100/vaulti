import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'backup_crypto.dart';
import 'models.dart';
import 'vault_marker.dart';

/// Le coffre enregistré existe, mais n'a pas pu être lu (stockage en erreur ou
/// contenu illisible). Distinct d'un coffre vide : l'appelant ne doit jamais
/// écrire par-dessus sans que l'utilisateur l'ait décidé.
class VaultUnreadableException implements Exception {
  const VaultUnreadableException();

  @override
  String toString() => 'Coffre illisible';
}

/// Accès au stockage sécurisé de l'appareil (chiffré par le système).
class VaultRepository {
  const VaultRepository([
    this._storage = const FlutterSecureStorage(),
    this._marker = const VaultMarker(),
  ]);

  final FlutterSecureStorage _storage;
  final VaultMarker _marker;

  static const _vaultKey = 'vault_data';
  static const _legacyVaultKey = 'vault_passwords';
  static const _userNameKey = 'user_name';
  static const _autoLockKey = 'auto_lock_seconds';
  static const _screenProtectionKey = 'screen_protection';
  static const _backupKeyKey = 'backup_key';
  static const _backupSaltKey = 'backup_salt';
  static const _backupIterationsKey = 'backup_iterations';
  static const _isPremiumKey = 'is_premium';

  /// Lit le coffre. Un coffre absent (premier lancement) donne un coffre vide ;
  /// un coffre présent mais illisible lève [VaultUnreadableException], sans rien
  /// modifier : renvoyer un coffre vide ici ferait écraser la donnée existante
  /// à la prochaine sauvegarde.
  Future<VaultData> loadVault() async {
    final String? raw;
    try {
      raw = await _storage.read(key: _vaultKey) ?? await _storage.read(key: _legacyVaultKey);
    } catch (_) {
      throw const VaultUnreadableException();
    }
    if (raw == null || raw.isEmpty) {
      // Aucun coffre dans le stockage sécurisé : premier lancement, sauf si un
      // coffre y a déjà été enregistré (repère présent). Il a alors disparu sans
      // que l'utilisateur l'ait décidé.
      if (await _marker.exists()) throw const VaultUnreadableException();
      return VaultData.empty();
    }
    final VaultData data;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List && decoded is! Map) throw const FormatException();
      data = VaultData.fromDecoded(decoded);
    } catch (_) {
      // FormatException, mais aussi TypeError sur une fiche mal formée.
      throw const VaultUnreadableException();
    }
    // Un coffre lu avec succès pose aussi le repère : ceux qui avaient déjà un
    // coffre avant cette protection en profitent dès la première ouverture, sans
    // attendre leur prochain enregistrement.
    await _marker.mark();
    return data;
  }

  Future<void> saveVault(VaultData data) async {
    await _storage.write(key: _vaultKey, value: jsonEncode(data.toJson()));
    // Après l'écriture réussie seulement : un repère sans coffre déclencherait
    // une fausse alerte.
    await _marker.mark();
  }

  Future<String?> readUserName() async {
    final name = await _storage.read(key: _userNameKey);
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  Future<void> saveUserName(String name) {
    return _storage.write(key: _userNameKey, value: name.trim());
  }

  /// Délai avant verrouillage automatique. Voir [AutoLockDelay].
  Future<AutoLockDelay> readAutoLockDelay() async {
    final raw = await _storage.read(key: _autoLockKey);
    final seconds = int.tryParse(raw ?? '');
    return AutoLockDelay.fromSeconds(seconds);
  }

  Future<void> saveAutoLockDelay(AutoLockDelay delay) {
    return _storage.write(key: _autoLockKey, value: delay.seconds.toString());
  }

  /// Protection contre les captures d'écran. Activée par défaut.
  Future<bool> readScreenProtection() async {
    final raw = await _storage.read(key: _screenProtectionKey);
    return raw != 'off';
  }

  Future<void> saveScreenProtection(bool enabled) {
    return _storage.write(key: _screenProtectionKey, value: enabled ? 'on' : 'off');
  }

  /// Clé de sauvegarde dérivée de la phrase secrète.
  ///
  /// On conserve la clé, jamais la phrase : cela permet de rafraîchir la
  /// sauvegarde à chaque modification sans redemander la phrase, tout en
  /// restant protégé par le magasin de clés du téléphone. Sur un nouvel
  /// appareil ce stockage est vide, et la phrase redevient indispensable.
  ///
  /// Le nombre d'itérations qui a produit la clé est conservé avec elle. Les clés
  /// enregistrées avant cette valeur datent de l'ancien format : 120 000.
  Future<({List<int> key, List<int> salt, int iterations})?> readBackupKey() async {
    final key = await _storage.read(key: _backupKeyKey);
    final salt = await _storage.read(key: _backupSaltKey);
    if (key == null || salt == null) return null;
    final stored = int.tryParse(await _storage.read(key: _backupIterationsKey) ?? '');
    final iterations = stored != null && stored >= BackupCrypto.minIterations && stored <= BackupCrypto.maxIterations
        ? stored
        : BackupCrypto.legacyIterations;
    try {
      return (key: base64Decode(key), salt: base64Decode(salt), iterations: iterations);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveBackupKey(List<int> key, List<int> salt, int iterations) async {
    await _storage.write(key: _backupKeyKey, value: base64Encode(key));
    await _storage.write(key: _backupSaltKey, value: base64Encode(salt));
    await _storage.write(key: _backupIterationsKey, value: iterations.toString());
  }

  /// Statut Premium (achat unique). Sans vérification serveur : comme la
  /// plupart des petites applications indépendantes, la validation reste
  /// côté appareil.
  Future<bool> readIsPremium() async {
    return (await _storage.read(key: _isPremiumKey)) == 'on';
  }

  Future<void> saveIsPremium(bool isPremium) {
    return _storage.write(key: _isPremiumKey, value: isPremium ? 'on' : 'off');
  }
}

/// Délais proposés pour le verrouillage automatique.
enum AutoLockDelay {
  immediate(0, 'Immédiat'),
  oneMinute(60, 'Après 1 minute'),
  fiveMinutes(300, 'Après 5 minutes'),
  never(-1, 'Jamais');

  const AutoLockDelay(this.seconds, this.label);

  /// Durée d'inactivité tolérée en arrière-plan ; -1 désactive le verrouillage.
  final int seconds;
  final String label;

  static const defaultDelay = AutoLockDelay.oneMinute;

  bool get isEnabled => seconds >= 0;

  static AutoLockDelay fromSeconds(int? seconds) {
    if (seconds == null) return defaultDelay;
    for (final delay in values) {
      if (delay.seconds == seconds) return delay;
    }
    return defaultDelay;
  }
}
