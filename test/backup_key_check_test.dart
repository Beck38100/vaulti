import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/backup_crypto.dart';
import 'package:vaulti/backup_service.dart';
import 'package:vaulti/models.dart';
import 'package:vaulti/vault_marker.dart';
import 'package:vaulti/vault_repository.dart';

/// Le minimum autorisé suffit pour tester le circuit sans ralentir la suite.
const _iterations = BackupCrypto.minIterations;
const _passphrase = 'phrase-de-test-assez-longue';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const crypto = BackupCrypto();
  const service = BackupService();

  /// Clé conservée comme l'application le fait : dérivée de [passphrase] avec un sel neuf.
  Future<({List<int> key, List<int> salt})> storedKey(String passphrase, int iterations) async {
    final salt = crypto.newSalt();
    final key = await crypto.deriveKey(passphrase, salt, iterations: iterations);
    return (key: await key.extractBytes(), salt: salt);
  }

  group('vérification du mot de passe de sauvegarde actuel', () {
    test('le bon mot de passe est reconnu', () async {
      final stored = await storedKey(_passphrase, _iterations);

      final ok = await service.matchesKey(_passphrase, key: stored.key, salt: stored.salt, iterations: _iterations);

      expect(ok, isTrue);
    });

    test('un mauvais mot de passe est refusé', () async {
      final stored = await storedKey(_passphrase, _iterations);

      final ok = await service.matchesKey('une-autre-phrase', key: stored.key, salt: stored.salt, iterations: _iterations);

      expect(ok, isFalse);
    });

    test('les itérations de la clé comptent : une clé ancienne se vérifie avec les siennes', () async {
      final stored = await storedKey(_passphrase, BackupCrypto.legacyIterations);

      final withOwn = await service.matchesKey(
        _passphrase,
        key: stored.key,
        salt: stored.salt,
        iterations: BackupCrypto.legacyIterations,
      );
      final withOther = await service.matchesKey(_passphrase, key: stored.key, salt: stored.salt, iterations: _iterations);

      expect(withOwn, isTrue);
      expect(withOther, isFalse);
    });

    test('une clé tronquée ou de mauvaise longueur ne correspond jamais', () async {
      final stored = await storedKey(_passphrase, _iterations);

      final ok = await service.matchesKey(
        _passphrase,
        key: stored.key.sublist(0, stored.key.length - 1),
        salt: stored.salt,
        iterations: _iterations,
      );

      expect(ok, isFalse);
    });
  });

  group('clé de sauvegarde enregistrée puis rechargée', () {
    late Directory documents;

    setUp(() {
      // Dossier de l'application de test, vide.
      documents = Directory.systemTemp.createTempSync('vaulti-documents-test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => documents.path,
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
        documents.deleteSync(recursive: true);
      });
    });

    Future<VaultRepository> freshRepository() async {
      final dir = Directory.systemTemp.createTempSync('vaulti-repere-test');
      addTearDown(() => dir.deleteSync(recursive: true));
      return VaultRepository(const FlutterSecureStorage(), VaultMarker(() async => dir));
    }

    test('la clé rechargée vérifie le mot de passe', () async {
      // Sauvegarde chiffrée de départ.
      final salt = crypto.newSalt();
      final key = await crypto.deriveKey(_passphrase, salt, iterations: _iterations);
      final envelope = await crypto.encrypt(
        plainText: jsonEncode(VaultData.empty().toJson()),
        key: key,
        salt: salt,
        iterations: _iterations,
      );

      // Restauration, comme _restoreFrom : la clé est enregistrée.
      FlutterSecureStorage.setMockInitialValues({});
      final restored = await service.restore(envelope, _passphrase);
      final first = await freshRepository();
      await first.saveBackupKey(await restored.key.extractBytes(), restored.salt, restored.iterations);
      expect(await service.readEnvelope(), isNull, reason: 'état de départ : dossier vide');

      // Redémarrage de l'appli : nouvel objet, mêmes données stockées (comme _loadBackupKey).
      final reloaded = await (await freshRepository()).readBackupKey();

      expect(reloaded, isNotNull, reason: 'la clé de sauvegarde est rechargée au démarrage');
      expect(reloaded!.iterations, _iterations);
      expect(
        await service.matchesKey(_passphrase, key: reloaded.key, salt: reloaded.salt, iterations: reloaded.iterations),
        isTrue,
      );
      expect(
        await service.matchesKey('mauvais-mot-de-passe', key: reloaded.key, salt: reloaded.salt, iterations: reloaded.iterations),
        isFalse,
      );
    });
  });
}
