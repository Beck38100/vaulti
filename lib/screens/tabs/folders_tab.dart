import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/vault_items.dart';
import '../vault_session.dart';

/// Arborescence des dossiers, à partir de la racine.
class FoldersTab extends StatelessWidget {
  const FoldersTab({super.key, required this.session});

  final VaultSession session;

  @override
  Widget build(BuildContext context) {
    final roots = session.foldersIn(null);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const SectionHeader(
          title: 'Dossiers',
          subtitle: 'À la racine de ton coffre — ouvre un dossier pour voir ses sous-dossiers',
          color: AppColors.folder,
        ),
        const SizedBox(height: 20),
        // La création passe par le bouton « + » de la barre du bas.
        if (roots.isEmpty)
          const EmptyState('Aucun dossier', hint: 'Les dossiers regroupent tes fiches par thème ou par personne.', icon: Icons.folder_outlined),
        ...roots.map((folder) => FolderRow(
              folder: folder,
              itemCount: session.itemCountIn(folder.id),
              onOpen: () {
                session.onOpenFolder(folder.id);
                session.onGoToTab(0);
              },
              actions: session.folderActions(folder),
            )),
      ],
    );
  }
}
