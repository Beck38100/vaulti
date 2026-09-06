import 'package:flutter/material.dart';

import '../item_visuals.dart';
import '../models.dart';
import '../theme.dart';
import 'animations.dart';
import 'common.dart';

/// Actions disponibles sur une fiche ou un dossier.
class ItemActions {
  const ItemActions({
    required this.onEdit,
    required this.onMove,
    required this.onDelete,
    this.onCopy,
    this.onReveal,
  });

  final VoidCallback onEdit;
  final VoidCallback onMove;

  /// Demande la suppression et indique si elle a bien été confirmée : le
  /// balayage a besoin de cette réponse pour savoir s'il doit escamoter la
  /// ligne ou la remettre en place.
  final Future<bool> Function() onDelete;
  final VoidCallback? onCopy;
  final VoidCallback? onReveal;
}

PopupMenuButton<String> _itemMenu(ItemActions actions, {bool canCopy = false}) {
  return PopupMenuButton<String>(
    onSelected: (value) {
      switch (value) {
        case 'copy':
          actions.onCopy?.call();
        case 'edit':
          actions.onEdit();
        case 'move':
          actions.onMove();
        case 'delete':
          actions.onDelete();
      }
    },
    itemBuilder: (_) => [
      if (canCopy) const PopupMenuItem(value: 'copy', child: Text('Copier le mot de passe')),
      const PopupMenuItem(value: 'edit', child: Text('Modifier')),
      const PopupMenuItem(value: 'move', child: Text('Déplacer')),
      const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
    ],
    icon: const Icon(Icons.more_vert, color: Colors.white54),
  );
}

/// Rend une ligne effaçable d'un glissement vers la gauche.
///
/// La suppression réutilise la fenêtre de confirmation habituelle : si elle est
/// annulée, la ligne revient en place.
class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({required this.itemKey, required this.onDelete, required this.child});

  final String itemKey;
  final Future<bool> Function() onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('swipe-$itemKey'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.warning),
      ),
      child: child,
    );
  }
}

/// Un dossier en vue liste.
class FolderRow extends StatelessWidget {
  const FolderRow({
    super.key,
    required this.folder,
    required this.itemCount,
    required this.onOpen,
    required this.actions,
  });

  final VaultFolder folder;
  final int itemCount;
  final VoidCallback onOpen;
  final ItemActions actions;

  @override
  Widget build(BuildContext context) => AppearIn(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _SwipeToDelete(
            itemKey: folder.id,
            onDelete: actions.onDelete,
            child: VaultRow(
              icon: Icons.folder_outlined,
              iconColor: AppColors.folder,
              title: folder.title.isEmpty ? 'Dossier' : folder.title,
              subtitle: '$itemCount élément${itemCount == 1 ? '' : 's'}',
              onTap: onOpen,
              trailing: _itemMenu(actions),
            ),
          ),
        ),
      );
}

/// Une fiche (mot de passe ou note) en vue liste.
class EntryRow extends StatelessWidget {
  const EntryRow({
    super.key,
    required this.entry,
    required this.revealed,
    required this.actions,
    this.folderLabel,
  });

  final VaultEntry entry;
  final bool revealed;
  final ItemActions actions;

  /// Chemin du dossier de la fiche, ajouté au sous-titre dans les vues qui
  /// mélangent plusieurs dossiers (onglets Mots de passe et Notes) — sans lui,
  /// rien n'indique où se trouve chaque fiche.
  final String? folderLabel;

  @override
  Widget build(BuildContext context) {
    final typeColor = entry.isNote ? AppColors.note : AppColors.password;
    final hidden = entry.isNote
        ? 'Note protégée'
        : (entry.identifier.isEmpty ? 'Identifiant non renseigné' : entry.identifier);

    return AppearIn(
      child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SwipeToDelete(
        itemKey: entry.id,
        onDelete: actions.onDelete,
        child: VaultRow(
        icon: entryIcon(entry),
        iconColor: typeColor,
        title: entry.title.isEmpty ? 'Accès' : entry.title,
        subtitle: [revealed ? entry.revealedContent : hidden, ?folderLabel].join(' · '),
        onTap: actions.onEdit,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            tooltip: revealed ? 'Masquer' : 'Révéler',
            icon: Icon(
              revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white54,
              size: 20,
            ),
            onPressed: actions.onReveal,
          ),
          _itemMenu(actions, canCopy: !entry.isNote),
        ]),
        ),
      ),
      ),
    );
  }
}

/// Un dossier en vue grille.
class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.folder,
    required this.itemCount,
    required this.onOpen,
    required this.actions,
  });

  final VaultFolder folder;
  final int itemCount;
  final VoidCallback onOpen;
  final ItemActions actions;

  @override
  Widget build(BuildContext context) {
    final title = folder.title.isEmpty ? 'Dossier' : folder.title;
    return AppearIn(
      child: Material(
      color: folderColor(title),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(folderIcon(title), color: const Color(0xFFE8E5DC), size: 24),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.folder, shape: BoxShape.circle),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      actions.onEdit();
                    case 'move':
                      actions.onMove();
                    case 'delete':
                      actions.onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(value: 'move', child: Text('Déplacer')),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
                icon: const Icon(Icons.more_horiz, color: Colors.white54, size: 20),
              ),
            ]),
            const Spacer(),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.onCard, fontWeight: FontWeight.w700, fontSize: 16)),
            Text('$itemCount ${itemCount == 1 ? 'élément' : 'éléments'}',
                style: const TextStyle(color: AppColors.onCardMuted, fontSize: 12)),
          ]),
        ),
      ),
      ),
    );
  }
}
