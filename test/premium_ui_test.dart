import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/dialogs.dart';
import 'package:vaulti/models.dart';
import 'package:vaulti/screens/tabs/settings_tab.dart';
import 'package:vaulti/screens/vault_session.dart';
import 'package:vaulti/theme.dart';
import 'package:vaulti/vault_repository.dart';
import 'package:vaulti/vault_stats.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: child),
    );

VaultSession fakeSession({
  bool isPremium = false,
  List<VaultFolder> folders = const [],
  List<VaultEntry> entries = const [],
}) {
  return VaultSession(
    folders: folders,
    entries: entries,
    stats: VaultStats.from(entries),
    revealedIds: const {},
    userName: 'Test',
    currentFolderId: null,
    onToggleReveal: (_) {},
    onCopyPassword: (_) {},
    onEditEntry: (_) {},
    onMoveEntry: (_) {},
    onDeleteEntry: (_) async => true,
    onEditFolder: (_) {},
    onMoveFolder: (_) {},
    onDeleteFolder: (_) async => true,
    onOpenFolder: (_) {},
    onAddFolder: () {},
    onGoToTab: (_) {},
    onRenameUser: () {},
    autoLockDelay: AutoLockDelay.defaultDelay,
    onAutoLockChanged: (_) {},
    screenProtection: true,
    onScreenProtectionChanged: (_) {},
    hasBackupPassphrase: false,
    onConfigureBackup: () {},
    onExportBackup: () {},
    onImportBackup: () {},
    isPremium: isPremium,
    onTogglePremiumForTesting: (_) {},
  );
}

void main() {
  testWidgets('la boîte de paywall explique la limite atteinte', (tester) async {
    await tester.pumpWidget(wrap(Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () => showPaywallDialog(context, limitLabel: '3 dossiers'),
        child: const Text('ouvrir'),
      );
    })));

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Limite atteinte'), findsOneWidget);
    expect(find.textContaining('3 dossiers'), findsOneWidget);
    expect(find.text('Voir Premium'), findsOneWidget);
  });

  testWidgets('l’intro gratuite annonce les trois limites', (tester) async {
    await tester.pumpWidget(wrap(Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () => showFreeTierIntro(context),
        child: const Text('ouvrir'),
      );
    })));

    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Version gratuite'), findsOneWidget);
    expect(find.textContaining('3 dossiers'), findsOneWidget);
    expect(find.textContaining('20 mots de passe'), findsOneWidget);
    expect(find.textContaining('10 notes'), findsOneWidget);
  });

  testWidgets('les réglages affichent le suivi de la version gratuite', (tester) async {
    // La liste des réglages dépasse la hauteur par défaut du test : on agrandit
    // la fenêtre plutôt que de faire défiler jusqu'à la section Premium.
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final entries = [
      VaultEntry(id: 'p1', type: VaultItemType.password, title: 'p1'),
      VaultEntry(id: 'n1', type: VaultItemType.note, title: 'n1'),
    ];
    await tester.pumpWidget(wrap(SettingsTab(session: fakeSession(entries: entries))));
    await tester.pumpAndSettle();

    expect(find.text('Version gratuite'), findsOneWidget);
    expect(find.text('1 / 20'), findsOneWidget); // mots de passe
    expect(find.text('1 / 10'), findsOneWidget); // notes
    expect(find.text('0 / 3'), findsOneWidget); // dossiers
    expect(find.text('Passer à Premium (test)'), findsOneWidget);
  });

  testWidgets('les réglages affichent le statut Premium sans limite', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(SettingsTab(session: fakeSession(isPremium: true))));
    await tester.pumpAndSettle();

    expect(find.text('Premium actif'), findsOneWidget);
    expect(find.text('Passer à Premium (test)'), findsNothing);
  });
}
