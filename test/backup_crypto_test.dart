import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:password_app/backup_crypto.dart';

/// Chiffre un contenu et renvoie l'enveloppe, comme le fait l'application.
Future<String> seal(BackupCrypto crypto, String clear, String passphrase) async {
  final salt = crypto.newSalt();
  final key = await crypto.deriveKey(passphrase, salt);
  return crypto.encrypt(plainText: clear, key: key, salt: salt);
}

/// Tente de déchiffrer une enveloppe avec une phrase donnée.
Future<String> open(BackupCrypto crypto, String envelope, String passphrase) async {
  final key = await crypto.deriveKey(passphrase, crypto.saltOf(envelope));
  return crypto.decrypt(envelope: envelope, key: key);
}

void main() {
  const crypto = BackupCrypto();
  const secret = '{"entries":[{"title":"Banque","pass":"S3cr3t!"}]}';

  test('un contenu chiffré se retrouve à l’identique', () async {
    final envelope = await seal(crypto, secret, 'ma phrase secrète');

    expect(await open(crypto, envelope, 'ma phrase secrète'), secret);
  });

  test('le contenu n’apparaît jamais en clair dans le fichier', () async {
    final envelope = await seal(crypto, secret, 'ma phrase secrète');

    expect(envelope.contains('Banque'), isFalse);
    expect(envelope.contains('S3cr3t!'), isFalse);
  });

  test('une phrase erronée est refusée, pas silencieusement acceptée', () async {
    final envelope = await seal(crypto, secret, 'la bonne phrase');

    expect(
      () => open(crypto, envelope, 'la mauvaise phrase'),
      throwsA(isA<BackupDecryptException>()),
    );
  });

  test('deux sauvegardes du même contenu diffèrent', () async {
    final first = await seal(crypto, secret, 'même phrase');
    final second = await seal(crypto, secret, 'même phrase');

    // Sel et nonce étant tirés au hasard, deux fichiers identiques
    // révéleraient une réutilisation dangereuse.
    expect(first, isNot(second));
  });

  test('un fichier altéré est détecté', () async {
    final envelope = await seal(crypto, secret, 'ma phrase');
    final tampered = jsonDecode(envelope) as Map<String, dynamic>;
    final data = base64Decode(tampered['data'] as String);
    data[0] = data[0] ^ 0xFF; // on modifie un octet
    tampered['data'] = base64Encode(data);

    expect(
      () => open(crypto, jsonEncode(tampered), 'ma phrase'),
      throwsA(isA<BackupDecryptException>()),
    );
  });

  test('un fichier qui n’est pas une sauvegarde donne un message clair', () async {
    expect(
      () => open(crypto, 'ceci est un texte quelconque', 'peu importe'),
      throwsA(isA<BackupDecryptException>()),
    );
  });

  test('une sauvegarde d’une version future est refusée explicitement', () async {
    final envelope = await seal(crypto, secret, 'ma phrase');
    final future = jsonDecode(envelope) as Map<String, dynamic>;
    future['version'] = BackupCrypto.formatVersion + 1;

    await expectLater(
      () => open(crypto, jsonEncode(future), 'ma phrase'),
      throwsA(predicate((e) => e is BackupDecryptException && e.reason.contains('plus récente'))),
    );
  });

  test('les accents et caractères spéciaux survivent au chiffrement', () async {
    const accented = 'Clé d’accès : éàüñ 中文 🔐';
    final envelope = await seal(crypto, accented, 'phrase');

    expect(await open(crypto, envelope, 'phrase'), accented);
  });
}
