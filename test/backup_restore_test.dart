import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:password_app/backup_crypto.dart';
import 'package:password_app/models.dart';

/// Reproduit le scénario complet « je perds mon téléphone » :
/// un coffre est sauvegardé, chiffré, puis relu sur un appareil neuf où seule
/// la phrase secrète est connue.
void main() {
  const crypto = BackupCrypto();

  VaultData sampleVault() => VaultData(
        folders: [VaultFolder(id: 'f1', title: 'Banque')],
        entries: [
          VaultEntry(
            id: 'e1',
            type: VaultItemType.password,
            title: 'Banque en ligne',
            identifier: 'jean.dupont',
            password: 'K7!vQ2xr#Lm9pZ',
            comment: 'carte bleue',
            folderId: 'f1',
          ),
          VaultEntry(id: 'e2', type: VaultItemType.note, title: 'Code portail', identifier: 'B3204'),
        ],
      );

  test('un coffre sauvegardé se retrouve intact sur un appareil neuf', () async {
    const passphrase = 'ma phrase de secours';

    // Ancien téléphone : on chiffre le coffre.
    final salt = crypto.newSalt();
    final key = await crypto.deriveKey(passphrase, salt);
    final envelope = await crypto.encrypt(
      plainText: jsonEncode(sampleVault().toJson()),
      key: key,
      salt: salt,
    );

    // Nouveau téléphone : rien en mémoire, seule la phrase est connue.
    final recoveredKey = await crypto.deriveKey(passphrase, crypto.saltOf(envelope));
    final clear = await crypto.decrypt(envelope: envelope, key: recoveredKey);
    final restored = VaultData.fromDecoded(jsonDecode(clear));

    expect(restored.folders.single.title, 'Banque');
    expect(restored.entries, hasLength(2));

    final account = restored.entries.firstWhere((e) => e.id == 'e1');
    expect(account.password, 'K7!vQ2xr#Lm9pZ');
    expect(account.identifier, 'jean.dupont');
    expect(account.comment, 'carte bleue');
    expect(account.folderId, 'f1');

    final note = restored.entries.firstWhere((e) => e.id == 'e2');
    expect(note.isNote, isTrue);
    expect(note.identifier, 'B3204');
  });

  test('sans la phrase, la sauvegarde reste inexploitable', () async {
    final salt = crypto.newSalt();
    final key = await crypto.deriveKey('la vraie phrase', salt);
    final envelope = await crypto.encrypt(
      plainText: jsonEncode(sampleVault().toJson()),
      key: key,
      salt: salt,
    );

    // Aucun mot de passe ne doit transparaître dans le fichier.
    expect(envelope.contains('K7!vQ2xr#Lm9pZ'), isFalse);
    expect(envelope.contains('jean.dupont'), isFalse);
    expect(envelope.contains('Banque'), isFalse);

    final wrongKey = await crypto.deriveKey('une autre phrase', crypto.saltOf(envelope));
    expect(
      () => crypto.decrypt(envelope: envelope, key: wrongKey),
      throwsA(isA<BackupDecryptException>()),
    );
  });

  test('un coffre vide se sauvegarde et se restaure sans erreur', () async {
    final salt = crypto.newSalt();
    final key = await crypto.deriveKey('phrase', salt);
    final envelope = await crypto.encrypt(
      plainText: jsonEncode(VaultData.empty().toJson()),
      key: key,
      salt: salt,
    );

    final clear = await crypto.decrypt(envelope: envelope, key: key);
    final restored = VaultData.fromDecoded(jsonDecode(clear));

    expect(restored.entries, isEmpty);
    expect(restored.folders, isEmpty);
  });
}
