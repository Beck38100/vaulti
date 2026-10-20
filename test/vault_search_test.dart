import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/models.dart';
import 'package:vaulti/screens/vault_session.dart';

void main() {
  final entries = [
    VaultEntry(
      id: 'p1',
      type: VaultItemType.password,
      title: 'Banque en ligne',
      identifier: 'jean.dupont',
      password: 'Zx9-secret-factice',
    ),
    VaultEntry(
      id: 'n1',
      type: VaultItemType.note,
      title: 'Code portail',
      identifier: 'B3204-contenu-prive',
    ),
  ];

  List<String> ids(String query) => VaultSession.search(entries, query).map((e) => e.id).toList();

  group('recherche des fiches', () {
    test('un mot de passe se trouve par son titre', () {
      expect(ids('banque'), ['p1']);
    });

    test('un mot de passe se trouve par son identifiant', () {
      expect(ids('jean.dupont'), ['p1']);
    });

    test('le mot de passe lui-même n’est jamais cherché', () {
      expect(ids('secret-factice'), isEmpty);
    });

    test('une note se trouve par son titre', () {
      expect(ids('portail'), ['n1']);
    });

    test('la recherche d’une note porte sur son titre seulement', () {
      expect(ids('B3204'), isEmpty);
      expect(ids('contenu-prive'), isEmpty);
    });

    test('la casse est ignorée', () {
      expect(ids('BANQUE'), ['p1']);
      expect(ids('PORTAIL'), ['n1']);
    });

    test('une recherche vide renvoie tout', () {
      expect(ids('   '), ['p1', 'n1']);
    });
  });
}
