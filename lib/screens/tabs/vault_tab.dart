import 'package:flutter/material.dart';

import '../../models.dart';
import '../../theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/common.dart';
import '../../widgets/dashboard.dart';
import '../../widgets/vault_items.dart';
import '../vault_session.dart';

/// Onglet principal : salutation, score, puis un accès rapide à chaque
/// catégorie. La navigation dans l'arborescence des dossiers se fait depuis
/// l'onglet Dossiers, pas ici — l'accueil reste un tableau de bord, pas une
/// troisième façon de parcourir le même contenu.
class VaultTab extends StatefulWidget {
  const VaultTab({super.key, required this.session, required this.searchController});

  final VaultSession session;

  /// Détenu par l'écran principal, qui peut ainsi vider la recherche
  /// lorsqu'on revient sur l'onglet Coffre.
  final TextEditingController searchController;

  @override
  State<VaultTab> createState() => _VaultTabState();
}

class _VaultTabState extends State<VaultTab> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() => _query = widget.searchController.text);
  }

  /// Un dossier trouvé par la recherche s'ouvre dans l'onglet Dossiers,
  /// seul endroit où l'on parcourt l'arborescence.
  void _openFolderFromSearch(String folderId) {
    widget.searchController.clear();
    widget.session.onOpenFolder(folderId);
    widget.session.onGoToTab(3);
  }

  /// Le détail des fiches à corriger est porté par le bandeau d'alerte de la
  /// carte de score juste en dessous : pas de raison de le répéter ici.
  String _subtitle(VaultSession session) {
    if (session.entries.isEmpty && session.folders.isEmpty) {
      return 'Prêt à accueillir tes premiers accès';
    }
    return 'Ton coffre est à jour';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isSearching = _query.trim().isNotEmpty;
    final matchingFolders = VaultSession.searchFolders(session.folders, _query);
    final matchingEntries = VaultSession.search(session.entries, _query);
    final greeting = session.userName == null ? 'Hello !' : 'Hello ${session.userName}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        Text(greeting,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.greeting)),
        const SizedBox(height: 6),
        Text(_subtitle(session), style: TextStyle(color: Colors.grey.shade400)),
        const SizedBox(height: 22),
        ScoreCard(
          score: session.stats.score,
          toFixCount: session.stats.flagged.length,
          onShowIssues: () => session.onGoToTab(4),
          hasPasswords: session.passwords.isNotEmpty,
        ),
        const SizedBox(height: 22),
        TextField(
          controller: widget.searchController,
          decoration: fieldDecoration('Rechercher un dossier ou un compte')
              .copyWith(prefixIcon: const Icon(Icons.search, color: AppColors.signature)),
        ),
        const SizedBox(height: 22),
        if (isSearching)
          _SearchResults(
            session: session,
            query: _query,
            folders: matchingFolders,
            entries: matchingEntries,
            onOpenFolder: _openFolderFromSearch,
          )
        else
          Row(children: [
            Expanded(
              child: _CategoryTile(
                icon: Icons.folder_outlined,
                color: AppColors.folder,
                value: session.folders.length,
                label: 'Dossiers',
                onTap: () => session.onGoToTab(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CategoryTile(
                icon: Icons.key_outlined,
                color: AppColors.password,
                value: session.passwords.length,
                label: 'Mots de passe',
                onTap: () => session.onGoToTab(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CategoryTile(
                icon: Icons.notes_outlined,
                color: AppColors.note,
                value: session.notes.length,
                label: 'Notes',
                onTap: () => session.onGoToTab(2),
              ),
            ),
          ]),
      ],
    );
  }
}

/// Résultats de recherche : dossiers puis fiches correspondants, à plat.
/// Une recherche porte sur tout le coffre, pas seulement une catégorie — la
/// liste mélangée est attendue ici, contrairement à l'accueil au repos.
class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.session,
    required this.query,
    required this.folders,
    required this.entries,
    required this.onOpenFolder,
  });

  final VaultSession session;
  final String query;
  final List<VaultFolder> folders;
  final List<VaultEntry> entries;
  final ValueChanged<String> onOpenFolder;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty && entries.isEmpty) {
      return EmptyState(
        'Aucun résultat pour « ${query.trim()} »',
        hint: 'Essaie un autre mot, la recherche porte sur tout le coffre.',
        icon: Icons.search_off,
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final folder in folders)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FolderRow(
            key: ValueKey(folder.id),
            folder: folder,
            itemCount: session.itemCountIn(folder.id),
            onOpen: () => onOpenFolder(folder.id),
            actions: session.folderActions(folder),
          ),
        ),
      for (final entry in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: EntryRow(
            key: ValueKey(entry.id),
            entry: entry,
            revealed: session.isRevealed(entry),
            actions: session.entryActions(entry),
          ),
        ),
    ]);
  }
}

/// Accès rapide à une catégorie du coffre, depuis l'accueil : pastille
/// colorée, gros chiffre, libellé — même lecture qu'un coup d'œil sur un
/// tableau de bord, en restant tactile.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      builder: (context, onHighlightChanged) => Material(
        color: AppColors.surface,
        shape: cardShape(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: onHighlightChanged,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(height: 12),
              Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
            ]),
          ),
        ),
      ),
    );
  }
}
