import 'package:flutter/material.dart';

import '../models.dart';
import '../premium.dart';
import '../vault_repository.dart';
import '../vault_stats.dart';
import '../widgets/vault_items.dart';

/// Vue en lecture seule du coffre, accompagnée des actions disponibles.
///
/// Cet objet est construit une fois par l'écran principal puis transmis à chaque
/// onglet : les onglets restent ainsi de simples vues, sans logique métier.
class VaultSession {
  const VaultSession({
    required this.folders,
    required this.entries,
    required this.stats,
    required this.revealedIds,
    required this.userName,
    required this.currentFolderId,
    required this.onToggleReveal,
    required this.onCopyPassword,
    required this.onEditEntry,
    required this.onMoveEntry,
    required this.onDeleteEntry,
    required this.onEditFolder,
    required this.onMoveFolder,
    required this.onDeleteFolder,
    required this.onOpenFolder,
    required this.onAddFolder,
    required this.onGoToTab,
    required this.onRenameUser,
    required this.autoLockDelay,
    required this.onAutoLockChanged,
    required this.screenProtection,
    required this.onScreenProtectionChanged,
    required this.hasBackupPassphrase,
    required this.onConfigureBackup,
    required this.onExportBackup,
    required this.onImportBackup,
    required this.isPremium,
    required this.onTogglePremiumForTesting,
  });

  final List<VaultFolder> folders;
  final List<VaultEntry> entries;
  final VaultStats stats;
  final Set<String> revealedIds;
  final String? userName;

  /// Dossier actuellement ouvert dans l'onglet Coffre (null = racine).
  final String? currentFolderId;

  final ValueChanged<VaultEntry> onToggleReveal;
  final ValueChanged<VaultEntry> onCopyPassword;
  final ValueChanged<VaultEntry> onEditEntry;
  final ValueChanged<VaultEntry> onMoveEntry;
  final Future<bool> Function(VaultEntry) onDeleteEntry;

  final ValueChanged<VaultFolder> onEditFolder;
  final ValueChanged<VaultFolder> onMoveFolder;
  final Future<bool> Function(VaultFolder) onDeleteFolder;
  final ValueChanged<String?> onOpenFolder;
  final VoidCallback onAddFolder;

  final ValueChanged<int> onGoToTab;

  final VoidCallback onRenameUser;

  /// Réglages de sécurité, modifiables depuis l'onglet Réglages.
  final AutoLockDelay autoLockDelay;
  final ValueChanged<AutoLockDelay> onAutoLockChanged;
  final bool screenProtection;
  final ValueChanged<bool> onScreenProtectionChanged;

  /// Sauvegarde chiffrée : une phrase secrète est-elle déjà définie ?
  final bool hasBackupPassphrase;
  final VoidCallback onConfigureBackup;
  final VoidCallback onExportBackup;
  final VoidCallback onImportBackup;

  /// Débloqué par achat unique. Sans magasin branché pour l'instant, ce
  /// statut se simule depuis les Réglages en attendant l'intégration
  /// d'in_app_purchase.
  final bool isPremium;
  final ValueChanged<bool> onTogglePremiumForTesting;

  /// Usage courant face aux limites de la version gratuite.
  PremiumUsage get premiumUsage => PremiumUsage.from(folders, entries);

  /// Toutes les fiches de type mot de passe.
  List<VaultEntry> get passwords => entries.where((e) => !e.isNote).toList();

  /// Toutes les notes libres.
  List<VaultEntry> get notes => entries.where((e) => e.isNote).toList();

  bool isRevealed(VaultEntry entry) => revealedIds.contains(entry.id);

  List<VaultFolder> foldersIn(String? parentId) =>
      folders.where((folder) => folder.parentId == (parentId ?? '')).toList();

  List<VaultEntry> entriesIn(String? folderId) =>
      entries.where((entry) => entry.folderId == (folderId ?? '')).toList();

  /// Nombre d'éléments directement contenus dans un dossier.
  int itemCountIn(String folderId) => foldersIn(folderId).length + entriesIn(folderId).length;

  VaultFolder? folderById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final folder in folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  /// Chemin lisible d'un dossier, par exemple « Mon coffre > Famille ».
  String folderPath(String? folderId) {
    const root = 'Mon coffre';
    final folder = folderById(folderId);
    if (folder == null) return root;
    final parts = <String>[folder.title.isEmpty ? 'Dossier' : folder.title];
    var current = folder;
    // Garde-fou : un coffre corrompu pourrait contenir un cycle de dossiers.
    final visited = <String>{current.id};
    while (current.parentId.isNotEmpty) {
      final parent = folderById(current.parentId);
      if (parent == null || !visited.add(parent.id)) break;
      parts.insert(0, parent.title.isEmpty ? 'Dossier' : parent.title);
      current = parent;
    }
    return [root, ...parts].join(' > ');
  }

  ItemActions entryActions(VaultEntry entry) => ItemActions(
        onEdit: () => onEditEntry(entry),
        onMove: () => onMoveEntry(entry),
        onDelete: () => onDeleteEntry(entry),
        onCopy: entry.isNote ? null : () => onCopyPassword(entry),
        onReveal: () => onToggleReveal(entry),
      );

  ItemActions folderActions(VaultFolder folder) => ItemActions(
        onEdit: () => onEditFolder(folder),
        onMove: () => onMoveFolder(folder),
        onDelete: () => onDeleteFolder(folder),
      );

  /// Filtre les fiches par titre et identifiant, insensible à la casse.
  static List<VaultEntry> search(List<VaultEntry> source, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return source;
    return source
        .where((entry) => '${entry.title} ${entry.identifier}'.toLowerCase().contains(needle))
        .toList();
  }

  /// Filtre les dossiers par nom, insensible à la casse.
  static List<VaultFolder> searchFolders(List<VaultFolder> source, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return source;
    return source.where((folder) => folder.title.toLowerCase().contains(needle)).toList();
  }
}
