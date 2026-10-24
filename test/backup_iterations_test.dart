import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/backup_crypto.dart';
import 'package:vaulti/backup_service.dart';
import 'package:vaulti/models.dart';

/// Sauvegarde de TEST au format version 1 (120 000 itérations fixes), produite avec le
/// code d'avant ce changement. Mot de passe de test et contenu factices : aucune donnée réelle.
const _oldBackup = r'''{"version":1,"kdf":"pbkdf2-hmac-sha256","iterations":120000,"cipher":"aes-256-gcm","salt":"/gmaDDb/0RnLh7sC5pzVHw==","nonce":"skyGl3vbJ1JMVOui","data":"Ck7lvWS7Qs3/LfesnGiiAIfVMG/PapBT40PP/CngtmFHsrr+ZfU+PlU+2wjryBOWiq3vp/KiwGOBa1gl65Id8EyS2pyvoaYTVfZNUAtyxIvjjgUCRWVTXC8LuuTLG0pv1I0oCChUxnLMtJinlaKV+FxwPsgIC3prqXx7enkbz4Gw1Z0RHX1tK3/EcvFQFH/qa8O1Om0tyjox3yBZ8WN4fZWULBThwUNnRRlLzIl/sKVH/YzKChgK1NTwb9qaDz3ReNL1TGJ7","mac":"Ndh3jt7+vK74Ka4xXLLM8A=="}''';
const _oldPassphrase = 'phrase-de-test-v1';

Future<String> sealV2(BackupCrypto crypto, String clear, String passphrase, int iterations) async {
  final salt = crypto.newSalt();
  final key = await crypto.deriveKey(passphrase, salt, iterations: iterations);
  return crypto.encrypt(plainText: clear, key: key, salt: salt, iterations: iterations);
}

void main() {
  const crypto = BackupCrypto();
  const service = BackupService();

  group('ancien format (version 1)', () {
    test('une sauvegarde de version 1 se relit toujours avec son mot de passe', () async {
      final restored = await service.restore(_oldBackup, _oldPassphrase);

      expect(restored.iterations, BackupCrypto.legacyIterations);
      expect(restored.data.folders.single.title, 'Banque');
      expect(restored.data.entries.single.title, 'Compte de test');
      expect(restored.data.entries.single.password, 'mot-de-passe-factice');
    });

    test('un mauvais mot de passe reste refusé sur une ancienne sauvegarde', () async {
      await expectLater(service.restore(_oldBackup, 'autre-phrase'), throwsA(isA<BackupDecryptException>()));
    });

    test('pour la version 1, la valeur de l’en-tête est ignorée (120 000 fixes)', () async {
      final header = jsonDecode(_oldBackup) as Map<String, dynamic>;
      header['iterations'] = 1; // valeur absurde : ne doit rien changer en version 1

      expect(crypto.iterationsOf(jsonEncode(header)), BackupCrypto.legacyIterations);
      final restored = await service.restore(jsonEncode(header), _oldPassphrase);
      expect(restored.data.entries, hasLength(1));
    });

    test('restaurer une ancienne sauvegarde, puis la réécrire, donne une sauvegarde lisible', () async {
      final restored = await service.restore(_oldBackup, _oldPassphrase);

      // Comme l'application : la clé conservée sert aux sauvegardes suivantes.
      final rewritten = await crypto.encrypt(
        plainText: jsonEncode(restored.data.toJson()),
        key: restored.key,
        salt: restored.salt,
        iterations: restored.iterations,
      );
      final header = jsonDecode(rewritten) as Map<String, dynamic>;
      final again = await service.restore(rewritten, _oldPassphrase);

      expect(header['version'], BackupCrypto.formatVersion);
      expect(header['iterations'], BackupCrypto.legacyIterations);
      expect(again.data.entries.single.password, 'mot-de-passe-factice');
    });
  });

  group('nouveau format (version 2)', () {
    test('le fichier porte la version 2 et le nombre d’itérations utilisé', () async {
      final envelope = await sealV2(crypto, '{}', 'phrase de test assez longue', 110000);
      final header = jsonDecode(envelope) as Map<String, dynamic>;

      expect(header['version'], 2);
      expect(header['iterations'], 110000);
      expect(crypto.iterationsOf(envelope), 110000);
    });

    test('un nombre d’itérations différent du défaut se relit correctement', () async {
      final envelope = await sealV2(crypto, '{"folders":[],"entries":[]}', 'phrase de test assez longue', 130000);

      final restored = await service.restore(envelope, 'phrase de test assez longue');

      expect(restored.iterations, 130000);
      expect(restored.data.entries, isEmpty);
    });

    test('le nombre d’itérations de l’en-tête est protégé : le modifier fait échouer le déchiffrement', () async {
      final envelope = await sealV2(crypto, '{"folders":[],"entries":[]}', 'phrase de test assez longue', 110000);
      final tampered = jsonDecode(envelope) as Map<String, dynamic>;
      tampered['iterations'] = 120000; // valide, mais pas celui qui a servi

      await expectLater(
        service.restore(jsonEncode(tampered), 'phrase de test assez longue'),
        throwsA(isA<BackupDecryptException>()),
      );
    });

    for (final value in [0, 99999, 2000001, 999999999, -5]) {
      test('une valeur hors bornes ($value) est refusée avant tout calcul', () async {
        final envelope = await sealV2(crypto, '{}', 'phrase de test assez longue', 100000);
        final header = jsonDecode(envelope) as Map<String, dynamic>;
        header['iterations'] = value;

        expect(() => crypto.iterationsOf(jsonEncode(header)), throwsA(isA<BackupDecryptException>()));
      });
    }

    test('une valeur qui n’est pas un entier est refusée', () async {
      final envelope = await sealV2(crypto, '{}', 'phrase de test assez longue', 100000);
      final header = jsonDecode(envelope) as Map<String, dynamic>;

      for (final bad in ['120000', 1.5, null, true]) {
        header['iterations'] = bad;
        expect(() => crypto.iterationsOf(jsonEncode(header)), throwsA(isA<BackupDecryptException>()));
      }
    });

    test('les bornes sont acceptées aux extrémités', () async {
      final header = jsonDecode(await sealV2(crypto, '{}', 'phrase de test assez longue', 100000))
          as Map<String, dynamic>;

      header['iterations'] = BackupCrypto.minIterations;
      expect(crypto.iterationsOf(jsonEncode(header)), BackupCrypto.minIterations);
      header['iterations'] = BackupCrypto.maxIterations;
      expect(crypto.iterationsOf(jsonEncode(header)), BackupCrypto.maxIterations);
    });

    test('dériver ou chiffrer avec une valeur hors bornes est refusé', () async {
      final salt = crypto.newSalt();

      expect(() => crypto.deriveKey('x', salt, iterations: 1000), throwsArgumentError);
      expect(() => crypto.deriveKey('x', salt, iterations: BackupCrypto.maxIterations + 1), throwsArgumentError);
    });

    test('une sauvegarde de version 2 sans nombre d’itérations est refusée', () async {
      final envelope = await sealV2(crypto, '{}', 'phrase de test assez longue', 100000);
      final header = jsonDecode(envelope) as Map<String, dynamic>..remove('iterations');

      expect(() => crypto.iterationsOf(jsonEncode(header)), throwsA(isA<BackupDecryptException>()));
    });
  });

  test('la version actuelle est bien la 2 et la longueur minimale est de 12 caractères', () {
    expect(BackupCrypto.formatVersion, 2);
    expect(BackupCrypto.minPassphraseLength, 12);
    expect(VaultData.empty().entries, isEmpty);
  });

  test('les nouvelles clés utilisent 600 000 itérations, dans les bornes autorisées', () async {
    expect(BackupCrypto.defaultIterations, 600000);
    expect(BackupCrypto.defaultIterations, greaterThanOrEqualTo(BackupCrypto.minIterations));
    expect(BackupCrypto.defaultIterations, lessThanOrEqualTo(BackupCrypto.maxIterations));

    // Chemin complet de l'application : préparer une clé, écrire, relire avec le mot de passe.
    final prepared = await service.prepareKey('phrase de test assez longue');
    final envelope = await crypto.encrypt(
      plainText: '{"folders":[],"entries":[]}',
      key: prepared.key,
      salt: prepared.salt,
      iterations: prepared.iterations,
    );
    final header = jsonDecode(envelope) as Map<String, dynamic>;
    final restored = await service.restore(envelope, 'phrase de test assez longue');

    expect(prepared.iterations, 600000);
    expect(header['iterations'], 600000);
    expect(restored.iterations, 600000);
  });
}
