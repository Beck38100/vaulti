import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

/// Accès au stockage sécurisé de l'appareil (chiffré par le système).
class VaultRepository {
  const VaultRepository([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _vaultKey = 'vault_data';
  static const _legacyVaultKey = 'vault_passwords';
  static const _userNameKey = 'user_name';
  static const _autoLockKey = 'auto_lock_seconds';
  static const _screenProtectionKey = 'screen_protection';
  static const _backupKeyKey = 'backup_key';
  static const _backupSaltKey = 'backup_salt';

  Future<VaultData> loadVault() async {
    final raw = await _storage.read(key: _vaultKey) ?? await _storage.read(key: _legacyVaultKey);
    if (raw == null || raw.isEmpty) return VaultData.empty();
    try {
      return VaultData.fromDecoded(jsonDecode(raw));
    } on FormatException {
      // Coffre illisible : on repart d'un coffre vide plutôt que de planter.
      return VaultData.empty();
    }
  }

  Future<void> saveVault(VaultData data) {
    return _storage.write(key: _vaultKey, value: jsonEncode(data.toJson()));
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
  Future<({List<int> key, List<int> salt})?> readBackupKey() async {
    final key = await _storage.read(key: _backupKeyKey);
    final salt = await _storage.read(key: _backupSaltKey);
    if (key == null || salt == null) return null;
    try {
      return (key: base64Decode(key), salt: base64Decode(salt));
    } on FormatException {
      return null;
    }
  }

  Future<void> saveBackupKey(List<int> key, List<int> salt) async {
    await _storage.write(key: _backupKeyKey, value: base64Encode(key));
    await _storage.write(key: _backupSaltKey, value: base64Encode(salt));
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
