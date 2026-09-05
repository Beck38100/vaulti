import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/models.dart';

void main() {
  group('VaultData', () {
    test('relit le format enregistré sans rien perdre', () {
      final original = VaultData(
        folders: [VaultFolder(id: 'f1', title: 'Banque')],
        entries: [
          VaultEntry(
            id: 'e1',
            type: VaultItemType.password,
            title: 'Ma banque',
            identifier: 'jean',
            password: 'S3cr3t!',
            comment: 'carte bleue',
            folderId: 'f1',
          ),
          VaultEntry(id: 'e2', type: VaultItemType.note, title: 'Code portail', identifier: 'B3204'),
        ],
      );

      final restored = VaultData.fromDecoded(jsonDecode(jsonEncode(original.toJson())));

      expect(restored.folders.single.title, 'Banque');
      expect(restored.entries.first.password, 'S3cr3t!');
      expect(restored.entries.first.comment, 'carte bleue');
      expect(restored.entries.first.folderId, 'f1');
      expect(restored.entries.last.isNote, isTrue);
      expect(restored.entries.last.identifier, 'B3204');
    });

    test('conserve les clés historiques du stockage', () {
      final entry = VaultEntry(
        id: 'e1',
        type: VaultItemType.password,
        title: 'Mail',
        identifier: 'a@b.fr',
        password: 'x',
        comment: 'c',
        folderId: '',
      );

      // Ces clés sont celles des coffres déjà enregistrés sur les téléphones :
      // les renommer rendrait les données existantes illisibles.
      expect(entry.toJson().keys, containsAll(['id', 'type', 'title', 'user', 'pass', 'note', 'folderId']));
      expect(entry.toJson()['user'], 'a@b.fr');
      expect(entry.toJson()['pass'], 'x');
    });

    test('accepte l’ancien format en simple liste de fiches', () {
      final decoded = jsonDecode('[{"id":"1","type":"password","title":"Ancien","pass":"abc"}]');

      final data = VaultData.fromDecoded(decoded);

      expect(data.folders, isEmpty);
      expect(data.entries.single.title, 'Ancien');
      expect(data.entries.single.password, 'abc');
    });

    test('attribue un identifiant aux fiches qui n’en ont pas', () {
      final decoded = jsonDecode('{"folders":[],"entries":[{"title":"Sans id"},{"title":"Sans id non plus"}]}');

      final data = VaultData.fromDecoded(decoded);

      expect(data.entries[0].id, isNotEmpty);
      expect(data.entries[1].id, isNotEmpty);
      expect(data.entries[0].id, isNot(data.entries[1].id));
    });

    test('ne plante pas sur un contenu inattendu', () {
      expect(VaultData.fromDecoded('n’importe quoi').entries, isEmpty);
    });
  });
}
