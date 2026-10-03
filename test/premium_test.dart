import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/models.dart';
import 'package:vaulti/premium.dart';

VaultFolder folder(String id) => VaultFolder(id: id, title: id);
VaultEntry password(String id) => VaultEntry(id: id, type: VaultItemType.password, title: id);
VaultEntry note(String id) => VaultEntry(id: id, type: VaultItemType.note, title: id);

void main() {
  group('PremiumUsage', () {
    test('compte les dossiers, mots de passe et notes séparément', () {
      final usage = PremiumUsage.from(
        [folder('a'), folder('b')],
        [password('p1'), note('n1'), note('n2')],
      );
      expect(usage.folderCount, 2);
      expect(usage.passwordCount, 1);
      expect(usage.noteCount, 2);
    });

    test('un coffre sous les limites ne déclenche rien', () {
      final usage = PremiumUsage.from([], []);
      expect(usage.folderLimitReached, isFalse);
      expect(usage.passwordLimitReached, isFalse);
      expect(usage.noteLimitReached, isFalse);
    });

    test('les limites gratuites sont celles annoncées sur la fiche Play Store', () {
      expect(PremiumLimits.maxFolders, 3);
      expect(PremiumLimits.maxPasswords, 10);
      expect(PremiumLimits.maxNotes, 8);
    });

    test('un coffre déjà au-dessus des limites reste utilisable et bloque seulement l’ajout', () {
      final usage = PremiumUsage.from(
        [],
        List.generate(PremiumLimits.maxPasswords + 5, (i) => password('p$i')),
      );
      expect(usage.passwordCount, PremiumLimits.maxPasswords + 5);
      expect(usage.passwordLimitReached, isTrue);
    });

    test('la limite se déclenche une fois le quota atteint', () {
      final usage = PremiumUsage.from(
        List.generate(PremiumLimits.maxFolders, (i) => folder('f$i')),
        [
          ...List.generate(PremiumLimits.maxPasswords, (i) => password('p$i')),
          ...List.generate(PremiumLimits.maxNotes, (i) => note('n$i')),
        ],
      );
      expect(usage.folderLimitReached, isTrue);
      expect(usage.passwordLimitReached, isTrue);
      expect(usage.noteLimitReached, isTrue);
    });
  });
}
