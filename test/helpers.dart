import 'package:flutter/material.dart';
import 'package:vaulti/models.dart';
import 'package:vaulti/screens/vault_session.dart';
import 'package:vaulti/theme.dart';
import 'package:vaulti/vault_repository.dart';
import 'package:vaulti/vault_stats.dart';

/// Place un widget dans une application minimale, aux couleurs de Vaulti :
/// sans ça, tout widget qui lit le thème ou ouvre un dialogue échoue.
Widget wrap(Widget child) => MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(body: child),
    );

/// Session inerte : toutes les actions ne font rien, seul le contenu compte.
/// Sert aux onglets, qui exigent une session complète pour se construire.
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
    purchaseInProgress: false,
    onBuyPremium: () {},
    onRestorePurchase: () {},
  );
}
