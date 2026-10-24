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

  testWidgets('un mot de passe de moins de 12 caractères est refusé, même moyen', (tester) async {
    String? result = 'inchangé';
    await openDialog(tester, (future) => future.then((value) => result = value));

    // 8 lettres : « Moyen » pour la jauge, donc pas « trop faible », mais trop court.
    await fill(tester, 'zxcvbnmk', 'zxcvbnmk');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Au moins 12 caractères pour protéger une sauvegarde.'), findsOneWidget);
    expect(result, 'inchangé');
  });

  testWidgets('11 caractères sont refusés, 12 sont acceptés', (tester) async {
    String? result = 'inchangé';
    await openDialog(tester, (future) => future.then((value) => result = value));

    await fill(tester, 'Xk9#mP2vLq!', 'Xk9#mP2vLq!'); // 11
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Au moins 12 caractères pour protéger une sauvegarde.'), findsOneWidget);
    expect(result, 'inchangé');

    await fill(tester, 'Xk9#mP2vLq!z', 'Xk9#mP2vLq!z'); // 12
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(result, 'Xk9#mP2vLq!z');
  });

  testWidgets('une phrase de passe longue en minuscules est acceptée', (tester) async {
    String? result;
    await openDialog(tester, (future) => future.then((value) => result = value));

    await fill(tester, 'quatre mots tres longs', 'quatre mots tres longs');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(result, 'quatre mots tres longs');
  });

  testWidgets('le champ annonce la longueur minimale', (tester) async {
    await openDialog(tester, (_) {});

    expect(find.text('Au moins 12 caractères'), findsOneWidget);
  });

  testWidgets('une confirmation différente est refusée', (tester) async {
    await openDialog(tester, (_) {});

    await fill(tester, 'Xk9#mP2vLq!z', 'Xk9#mP2vLq!y');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Les deux saisies ne correspondent pas.'), findsOneWidget);
  });
}
