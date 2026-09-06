import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/common.dart';
import '../../widgets/dashboard.dart';
import '../../widgets/vault_items.dart';
import '../vault_session.dart';

/// Onglet principal : salutation, score, puis contenu du dossier ouvert.
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
  bool _gridMode = true;

  /// Profondeur du dossier affiché lors de la construction précédente : elle
  /// détermine le sens du glissement (on entre ou on remonte).
  int _previousDepth = 0;

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

  /// Ouvre un dossier ; si on venait d'une recherche, on la referme pour
  /// afficher le contenu réel du dossier.
  void _openFolder(String folderId) {
    if (_query.isNotEmpty) widget.searchController.clear();
    widget.session.onOpenFolder(folderId);
  }

  void _goToParentFolder() {
    final current = widget.session.folderById(widget.session.currentFolderId);
    final parentId = current?.parentId ?? '';
    widget.session.onOpenFolder(parentId.isEmpty ? null : parentId);
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
    final currentFolderId = session.currentFolderId;
    final isSearching = _query.trim().isNotEmpty;
    // Une recherche porte sur l'ensemble du coffre (dossiers, mots de passe et
    // notes), et pas seulement sur le dossier ouvert : on cherche un élément,
    // sans avoir à se rappeler où il est rangé.
    final folders = isSearching
        ? VaultSession.searchFolders(session.folders, _query)
        : session.foldersIn(currentFolderId);
    final entries = isSearching
        ? VaultSession.search(session.entries, _query)
        : session.entriesIn(currentFolderId);
    final greeting = session.userName == null ? 'Hello !' : 'Hello ${session.userName}';
    // Nombre de niveaux sous la racine : sert à savoir si l'on descend ou remonte.
    final depth = currentFolderId == null ? 0 : session.folderPath(currentFolderId).split(' > ').length - 1;
    // Mémorisé après la construction, pour comparer au prochain changement.
    WidgetsBinding.instance.addPostFrameCallback((_) => _previousDepth = depth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        Text(greeting,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.greeting)),
        const SizedBox(height: 5),
        Text(_subtitle(session), style: TextStyle(color: Colors.grey.shade400)),
        const SizedBox(height: 16),
        ScoreCard(
          score: session.stats.score,
          toFixCount: session.stats.flagged.length,
          onShowIssues: () => session.onGoToTab(4),
          hasPasswords: session.passwords.isNotEmpty,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: widget.searchController,
          decoration: fieldDecoration('Rechercher un dossier ou un compte')
              .copyWith(prefixIcon: const Icon(Icons.search, color: AppColors.signature)),
        ),
        const SizedBox(height: 20),
        Row(children: [
          if (currentFolderId != null && !isSearching)
            IconButton(
              tooltip: 'Revenir au dossier parent',
              onPressed: _goToParentFolder,
              icon: const Icon(Icons.arrow_back),
            ),
          Expanded(
            child: Text(
              isSearching ? 'Résultats' : session.folderPath(currentFolderId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          ViewModeToggle(isGrid: _gridMode, onChanged: (value) => setState(() => _gridMode = value)),
        ]),
        const SizedBox(height: 12),
        const TypeLegend(),
        const SizedBox(height: 10),
        DirectionalSwitcher(
          depth: depth,
          previousDepth: _previousDepth,
          child: Column(
            key: ValueKey('$_gridMode|$currentFolderId|$isSearching'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (folders.isNotEmpty && _gridMode) _folderGrid(session, folders),
              if (folders.isNotEmpty && !_gridMode)
                ...folders.map((folder) => FolderRow(
                      key: ValueKey(folder.id),
                      folder: folder,
                      itemCount: session.itemCountIn(folder.id),
                      onOpen: () => _openFolder(folder.id),
                      actions: session.folderActions(folder),
                    )),
              ...entries.map((entry) => EntryRow(
                    key: ValueKey(entry.id),
                    entry: entry,
                    revealed: session.isRevealed(entry),
                    actions: session.entryActions(entry),
                  )),
            ],
          ),
        ),
        if (folders.isEmpty && entries.isEmpty)
          if (isSearching)
            EmptyState(
              'Aucun résultat pour « ${_query.trim()} »',
              hint: 'Essaie un autre mot, la recherche porte sur tout le coffre.',
              icon: Icons.search_off,
            )
          else if (currentFolderId == null)
            const EmptyState(
              'Ton coffre est vide',
              hint: 'Appuie sur le bouton + en bas pour créer ton premier dossier, '
                  'mot de passe ou note.',
              icon: Icons.lock_outline,
            )
          else
            const EmptyState(
              'Ce dossier est vide',
              hint: 'Utilise le bouton + pour y ajouter une fiche ou une note.',
              icon: Icons.folder_open_outlined,
            ),
      ],
    );
  }

  Widget _folderGrid(VaultSession session, List folders) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: folders
          .map<Widget>((folder) => FolderCard(
                key: ValueKey(folder.id),
                folder: folder,
                itemCount: session.itemCountIn(folder.id),
                onOpen: () => _openFolder(folder.id),
                actions: session.folderActions(folder),
              ))
          .toList(),
    );
  }
}
