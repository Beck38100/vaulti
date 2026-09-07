import 'package:flutter/material.dart';

import '../../models.dart';
import '../../theme.dart';
import '../../widgets/animations.dart';
import '../../widgets/common.dart';
import '../../widgets/vault_items.dart';
import '../vault_session.dart';

/// Le vrai navigateur de l'arborescence : ouvrir un dossier affiche ses
/// sous-dossiers et ses fiches, avec un fil d'Ariane pour remonter. C'est le
/// seul endroit de l'app où l'on parcourt les dossiers ainsi — l'accueil se
/// contente d'y renvoyer.
class FoldersTab extends StatefulWidget {
  const FoldersTab({super.key, required this.session});

  final VaultSession session;

  @override
  State<FoldersTab> createState() => _FoldersTabState();
}

class _FoldersTabState extends State<FoldersTab> {
  bool _gridMode = true;

  /// Profondeur affichée lors de la construction précédente : détermine le
  /// sens du glissement (on entre ou on remonte).
  int _previousDepth = 0;

  void _goToParentFolder() {
    final session = widget.session;
    final current = session.folderById(session.currentFolderId);
    final parentId = current?.parentId ?? '';
    session.onOpenFolder(parentId.isEmpty ? null : parentId);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final currentFolderId = session.currentFolderId;
    final folders = session.foldersIn(currentFolderId);
    // À la racine, les fiches non rangées dans un dossier restent réservées
    // aux onglets Mots de passe et Notes : cet onglet ne montre que des
    // dossiers tant qu'on n'en a pas ouvert un.
    final entries = currentFolderId == null ? const <VaultEntry>[] : session.entriesIn(currentFolderId);
    // Nombre de niveaux sous la racine : sert à savoir si l'on descend ou remonte.
    final depth = currentFolderId == null ? 0 : session.folderPath(currentFolderId).split(' > ').length - 1;
    // Mémorisé après la construction, pour comparer au prochain changement.
    WidgetsBinding.instance.addPostFrameCallback((_) => _previousDepth = depth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const SectionHeader(
          title: 'Dossiers',
          subtitle: 'Ouvre un dossier pour voir son contenu',
          color: AppColors.folder,
        ),
        const SizedBox(height: 20),
        Row(children: [
          // À la racine, le titre « Dossiers » juste au-dessus dit déjà où l'on
          // est : répéter « Mon coffre » ici serait redondant. Le chemin ne
          // redevient utile qu'une fois un dossier ouvert.
          if (currentFolderId != null) ...[
            IconButton(
              tooltip: 'Revenir au dossier parent',
              onPressed: _goToParentFolder,
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                session.folderPath(currentFolderId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ] else
            const Spacer(),
          ViewModeToggle(isGrid: _gridMode, onChanged: (value) => setState(() => _gridMode = value)),
        ]),
        // La légende des couleurs n'a de sens que face à un mélange de types :
        // à la racine, il n'y a que des dossiers.
        if (currentFolderId != null) ...[
          const SizedBox(height: 12),
          const TypeLegend(),
        ],
        const SizedBox(height: 10),
        DirectionalSwitcher(
          depth: depth,
          previousDepth: _previousDepth,
          child: Column(
            key: ValueKey('$_gridMode|$currentFolderId'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (folders.isNotEmpty && _gridMode) _folderGrid(session, folders),
              if (folders.isNotEmpty && !_gridMode)
                ...folders.map((folder) => FolderRow(
                      key: ValueKey(folder.id),
                      folder: folder,
                      itemCount: session.itemCountIn(folder.id),
                      onOpen: () => session.onOpenFolder(folder.id),
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
          if (currentFolderId == null)
            const EmptyState(
              'Aucun dossier',
              hint: 'Appuie sur le bouton + en bas pour créer ton premier dossier.',
              icon: Icons.folder_outlined,
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

  Widget _folderGrid(VaultSession session, List<VaultFolder> folders) {
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
                onOpen: () => session.onOpenFolder(folder.id),
                actions: session.folderActions(folder),
              ))
          .toList(),
    );
  }
}
