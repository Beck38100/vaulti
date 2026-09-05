import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';

import 'backup_crypto.dart';
import 'models.dart';

/// Gère la sauvegarde chiffrée du coffre.
///
/// Le fichier est déposé dans les données de l'application, à un emplacement
/// inclus dans la sauvegarde automatique d'Android : c'est elle qui l'emporte
/// vers le compte Google de l'utilisateur. L'application, elle, ne se connecte
/// à aucun serveur.
class BackupService {
  const BackupService([this._crypto = const BackupCrypto()]);

  final BackupCrypto _crypto;

  static const fileName = 'vaulti-sauvegarde.vaulti';

  /// Emplacement du fichier, à garder synchronisé avec les règles Android
  /// (android/app/src/main/res/xml/backup_rules.xml et data_extraction_rules.xml).
  /// Sur Android ce dossier est app_flutter/ : renommer le fichier ou changer de
  /// dossier sans toucher aux règles désactiverait silencieusement la sauvegarde.
  Future<File> _backupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  /// Écrit la sauvegarde chiffrée. Appelée à chaque modification du coffre.
  Future<void> write(VaultData data, SecretKey key, List<int> salt) async {
    final envelope = await _crypto.encrypt(
      plainText: jsonEncode(data.toJson()),
      key: key,
      salt: salt,
    );
    final file = await _backupFile();
    await file.writeAsString(envelope, flush: true);
  }

  /// Contenu de la sauvegarde locale, ou null si elle n'existe pas.
  Future<String?> readEnvelope() async {
    final file = await _backupFile();
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    return content.isEmpty ? null : content;
  }

  Future<bool> exists() async => (await _backupFile()).exists();

  Future<void> delete() async {
    final file = await _backupFile();
    if (await file.exists()) await file.delete();
  }

  /// Déchiffre une enveloppe avec une phrase secrète.
  ///
  /// Renvoie le coffre restauré et la clé dérivée, que l'appelant conserve
  /// pour les sauvegardes suivantes sans redemander la phrase.
  Future<({VaultData data, SecretKey key, List<int> salt})> restore(
    String envelope,
    String passphrase,
  ) async {
    final salt = _crypto.saltOf(envelope);
    final key = await _crypto.deriveKey(passphrase, salt);
    final clear = await _crypto.decrypt(envelope: envelope, key: key);

    final decoded = jsonDecode(clear);
    return (data: VaultData.fromDecoded(decoded), key: key, salt: salt);
  }

  /// Prépare une nouvelle protection à partir d'une phrase secrète choisie.
  Future<({SecretKey key, List<int> salt})> prepareKey(String passphrase) async {
    final salt = _crypto.newSalt();
    final key = await _crypto.deriveKey(passphrase, salt);
    return (key: key, salt: salt);
  }

  /// Nom proposé lors d'un export manuel, daté pour s'y retrouver.
  ///
  /// L'extension .txt est volontaire : le contenu reste chiffré, mais Android
  /// sait alors quoi proposer pour l'ouvrir, et l'utilisateur peut vérifier
  /// lui-même qu'il est bien illisible.
  String suggestedExportName() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return 'vaulti-sauvegarde-${now.year}-${two(now.month)}-${two(now.day)}.txt';
  }
}
