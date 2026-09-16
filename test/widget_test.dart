import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/models.dart';
import 'package:vaulti/theme.dart';
import 'package:vaulti/vault_stats.dart';
import 'package:vaulti/widgets/common.dart';
import 'package:vaulti/widgets/dashboard.dart';
import 'package:vaulti/widgets/vault_items.dart';

import 'helpers.dart';

void main() {
  testWidgets('la carte de score affiche le score', (tester) async {
    await tester.pumpWidget(wrap(const ScoreCard(score: 42)));
    await tester.pumpAndSettle();

    expect(find.text('42'), findsOneWidget);
    expect(find.text('Score de sécurité'), findsOneWidget);
  });

  testWidgets('les deux faiblesses ont chacune leur pastille', (tester) async {
    final flagged = FlaggedEntry(
      entry: VaultEntry(id: '1', type: VaultItemType.password, title: 'Netflix', password: 'azerty'),
      isWeak: true,
      isReused: true,
    );

    await tester.pumpWidget(wrap(Row(children: flagged.reasons.map((r) => WeaknessTag(r)).toList())));

    expect(find.text('faible'), findsOneWidget);
    expect(find.text('réutilisé'), findsOneWidget);
  });

  testWidgets('le bandeau d’alerte affiche son rappel et réagit au toucher', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(WarningStrip(
      title: 'Aucune sauvegarde configurée',
      subtitle: 'En cas de perte du téléphone, tout serait perdu',
      shape: cardShape(),
      onTap: () => tapped = true,
    )));

    expect(find.text('Aucune sauvegarde configurée'), findsOneWidget);
    expect(find.text('En cas de perte du téléphone, tout serait perdu'), findsOneWidget);

    await tester.tap(find.byType(WarningStrip));
    expect(tapped, isTrue);
  });

  testWidgets('le même bandeau sans sous-titre tient sur une seule ligne', (tester) async {
    await tester.pumpWidget(wrap(WarningStrip(title: '2 mots de passe à corriger', shape: cardShape())));

    expect(find.text('2 mots de passe à corriger'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('une fiche masque son contenu tant qu’elle n’est pas révélée', (tester) async {
    final entry = VaultEntry(
      id: '1',
      type: VaultItemType.password,
      title: 'Banque',
      identifier: 'jean',
      password: 'ultra-secret',
    );

    await tester.pumpWidget(wrap(EntryRow(
      entry: entry,
      revealed: false,
      actions: ItemActions(onEdit: () {}, onMove: () {}, onDelete: () async => true),
    )));

    expect(find.text('jean'), findsOneWidget);
    expect(find.text('ultra-secret'), findsNothing);
  });

  testWidgets('une fiche révélée affiche son mot de passe', (tester) async {
    final entry = VaultEntry(
      id: '1',
      type: VaultItemType.password,
      title: 'Banque',
      identifier: 'jean',
      password: 'ultra-secret',
    );

    await tester.pumpWidget(wrap(EntryRow(
      entry: entry,
      revealed: true,
      actions: ItemActions(onEdit: () {}, onMove: () {}, onDelete: () async => true),
    )));

    expect(find.text('ultra-secret'), findsOneWidget);
  });

  testWidgets('balayer une fiche vers la gauche demande sa suppression', (tester) async {
    var deleteAsked = false;
    final entry = VaultEntry(id: '1', type: VaultItemType.password, title: 'Banque', password: 'x');

    await tester.pumpWidget(wrap(EntryRow(
      entry: entry,
      revealed: false,
      actions: ItemActions(
        onEdit: () {},
        onMove: () {},
        onDelete: () async {
          deleteAsked = true;
          return false; // suppression annulée : la ligne doit revenir en place
        },
      ),
    )));

    await tester.drag(find.text('Banque'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(deleteAsked, isTrue);
    // Annulée, donc la fiche est toujours affichée.
    expect(find.text('Banque'), findsOneWidget);
  });
}
