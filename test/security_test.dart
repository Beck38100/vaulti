import 'package:flutter_test/flutter_test.dart';
import 'package:password_app/vault_repository.dart';

void main() {
  group('AutoLockDelay', () {
    test('propose un délai par défaut raisonnable', () {
      expect(AutoLockDelay.defaultDelay, AutoLockDelay.oneMinute);
      expect(AutoLockDelay.defaultDelay.isEnabled, isTrue);
    });

    test('retrouve un délai enregistré', () {
      expect(AutoLockDelay.fromSeconds(0), AutoLockDelay.immediate);
      expect(AutoLockDelay.fromSeconds(60), AutoLockDelay.oneMinute);
      expect(AutoLockDelay.fromSeconds(300), AutoLockDelay.fiveMinutes);
      expect(AutoLockDelay.fromSeconds(-1), AutoLockDelay.never);
    });

    test('retombe sur le défaut si la valeur est absente ou inconnue', () {
      expect(AutoLockDelay.fromSeconds(null), AutoLockDelay.defaultDelay);
      expect(AutoLockDelay.fromSeconds(42), AutoLockDelay.defaultDelay);
    });

    test('« Jamais » désactive le verrouillage', () {
      expect(AutoLockDelay.never.isEnabled, isFalse);
      // Les autres restent actifs, y compris le verrouillage immédiat.
      expect(AutoLockDelay.immediate.isEnabled, isTrue);
    });

    test('chaque délai a un libellé lisible', () {
      for (final delay in AutoLockDelay.values) {
        expect(delay.label, isNotEmpty);
      }
    });
  });
}
