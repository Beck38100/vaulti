import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/dialogs.dart';

import 'helpers.dart';

/// Ouvre le dialogue de choix du mot de passe de sauvegarde et renvoie ce qu'il
/// rendra une fois fermé.
Future<void> openDialog(WidgetTester tester, void Function(Future<String?>) onOpened) async {
  await tester.pumpWidget(wrap(Builder(builder: (context) {
    return ElevatedButton(
      onPressed: () => onOpened(askNewPassphrase(context)),
      child: const Text('ouvrir'),
    );
  })));
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester, String first, String second) async {
  await tester.enterText(find.byType(TextField).first, first);
  await tester.enterText(find.byType(TextField).last, second);
  await tester.pump();
}

void main() {
  testWidgets('un mot de passe trop courant est refusé pour la sauvegarde', (tester) async {
    String? result = 'inchangé';
    await openDialog(tester, (future) => future.then((value) => result = value));

    await fill(tester, 'azerty2024', 'azerty2024');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Trop faible pour protéger une sauvegarde'), findsOneWidget);
    expect(result, 'inchangé'); // le dialogue est resté ouvert
  });

  testWidgets('la jauge suit la saisie', (tester) async {
    await openDialog(tester, (_) {});

    expect(find.text('Force du mot de passe'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Xk9#mP2vLq!z');
    await tester.pump();

    expect(find.text('Solide'), findsOneWidget);
  });

  testWidgets('un mot de passe solide et confirmé est accepté', (tester) async {
    String? result;
    await openDialog(tester, (future) => future.then((value) => result = value));

    await fill(tester, 'Xk9#mP2vLq!z', 'Xk9#mP2vLq!z');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(result, 'Xk9#mP2vLq!z');
  });

  testWidgets('une confirmation différente est refusée', (tester) async {
    await openDialog(tester, (_) {});

    await fill(tester, 'Xk9#mP2vLq!z', 'Xk9#mP2vLq!y');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Les deux saisies ne correspondent pas.'), findsOneWidget);
  });
}
