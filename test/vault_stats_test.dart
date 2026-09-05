import 'package:flutter_test/flutter_test.dart';
import 'package:password_app/models.dart';
import 'package:password_app/password_strength.dart';
import 'package:password_app/vault_stats.dart';

VaultEntry password(String title, String value) =>
    VaultEntry(id: title, type: VaultItemType.password, title: title, password: value);

VaultEntry note(String title) => VaultEntry(id: title, type: VaultItemType.note, title: title);

void main() {
  group('evaluatePassword', () {
    test('classe un mot de passe court comme faible', () {
      expect(evaluatePassword('abc').isWeak, isTrue);
    });

    test('classe un mot de passe long et varié comme solide', () {
      expect(evaluatePassword('K7!vQ2xr#Lm9pZ').isSolid, isTrue);
    });

    test('un mot de passe moyen n’est ni faible ni solide', () {
      final result = evaluatePassword('azertyuiop');
      expect(result.isWeak, isFalse);
      expect(result.isSolid, isFalse);
    });
  });

  group('VaultStats', () {
    test('un coffre vide donne un score nul', () {
      final stats = VaultStats.from([]);
      expect(stats.score, 0);
      expect(stats.flagged, isEmpty);
    });

    test('les notes ne sont pas comptées dans le score', () {
      final stats = VaultStats.from([password('Banque', 'K7!vQ2xr#Lm9pZ'), note('Recette')]);
      expect(stats.score, 100);
      expect(stats.solidCount, 1);
    });

    test('signale les mots de passe faibles', () {
      final stats = VaultStats.from([password('Netflix', 'abc')]);

      expect(stats.weakCount, 1);
      expect(stats.flagged.single.entry.title, 'Netflix');
      expect(stats.flagged.single.reason, contains('faible'));
    });

    test('signale un mot de passe réutilisé sur plusieurs fiches', () {
      final stats = VaultStats.from([
        password('Netflix', 'K7!vQ2xr#Lm9pZ'),
        password('Impots', 'K7!vQ2xr#Lm9pZ'),
      ]);

      expect(stats.flagged, hasLength(2));
      expect(stats.flagged.every((f) => f.reason.contains('réutilisé')), isTrue);
      // Réutilisé mais robuste : ce n’est pas un mot de passe faible.
      expect(stats.weakCount, 0);
    });

    test('cumule les deux motifs quand ils s’appliquent', () {
      final stats = VaultStats.from([password('A', 'azerty'), password('B', 'azerty')]);

      expect(stats.flagged.first.reason, 'faible, réutilisé');
    });

    test('un mot de passe unique n’est jamais marqué réutilisé', () {
      final stats = VaultStats.from([
        password('A', 'K7!vQ2xr#Lm9pZ'),
        password('B', 'Zt4@wQ8er#Km1X'),
      ]);

      expect(stats.flagged, isEmpty);
    });

    test('le score est la moyenne des fiches', () {
      final stats = VaultStats.from([
        password('Solide', 'K7!vQ2xr#Lm9pZ'), // 1.0
        password('Faible', 'abc'), // 0.25
      ]);

      expect(stats.score, 63); // (1 + 0.25) / 2 = 0.625 -> 63 %
    });
  });
}
