import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/animations.dart';
import 'form_shell.dart';

/// Ce qu'on peut ajouter depuis le bouton « + ».
enum AddChoice { folder, password, note }

/// Menu du bouton « + ».
Future<AddChoice?> showAddMenu(BuildContext context) {
  return showModalBottomSheet<AddChoice>(
    context: context,
    backgroundColor: AppColors.sheet,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    sheetAnimationStyle: AnimationStyle(duration: Motion.normal, curve: Motion.spring),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 18),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Ajouter dans le coffre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          _SheetOption(
            color: AppColors.folder,
            icon: Icons.create_new_folder_outlined,
            title: 'Créer un dossier',
            subtitle: 'Organiser des comptes ou des membres',
            onTap: () => Navigator.pop(ctx, AddChoice.folder),
          ),
          _SheetOption(
            color: AppColors.password,
            icon: Icons.key_outlined,
            title: 'Renseigner un mot de passe',
            subtitle: 'Ajouter une fiche sécurisée',
            onTap: () => Navigator.pop(ctx, AddChoice.password),
          ),
          _SheetOption(
            color: AppColors.note,
            icon: Icons.notes_outlined,
            title: 'Créer une note',
            subtitle: 'Texte libre, sans champs imposés',
            onTap: () => Navigator.pop(ctx, AddChoice.note),
          ),
        ]),
      ),
    ),
  );
}

/// Proposé juste après la création d'un dossier.
Future<AddChoice?> showFolderNextStep(BuildContext context) {
  return showModalBottomSheet<AddChoice>(
    context: context,
    backgroundColor: AppColors.sheet,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Dossier créé', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Que veux-tu ajouter dans ce dossier ?'),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.key_outlined, color: AppColors.password),
            title: const Text('Renseigner un mot de passe'),
            onTap: () => Navigator.pop(ctx, AddChoice.password),
          ),
          ListTile(
            leading: const Icon(Icons.notes_outlined, color: AppColors.note),
            title: const Text('Créer une note'),
            onTap: () => Navigator.pop(ctx, AddChoice.note),
          ),
          ListTile(
            leading: const Icon(Icons.check, color: AppColors.folder),
            title: const Text('Juste créer le dossier'),
            subtitle: const Text('Terminer sans ajouter de contenu'),
            onTap: () => Navigator.pop(ctx),
          ),
        ]),
      ),
    ),
  );
}

/// Saisie ou modification du nom d'un dossier.
Future<String?> askFolderName(BuildContext context, {String? initialValue}) {
  final controller = TextEditingController(text: initialValue ?? '');
  final isNew = initialValue == null;
  String? error;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        void submit() {
          final title = controller.text.trim();
          if (title.isEmpty) {
            setDialogState(() => error = 'Donne un nom à ce dossier.');
            return;
          }
          Navigator.pop(ctx, title);
        }

        return VaultFormDialog(
          icon: Icons.create_new_folder_outlined,
          accent: AppColors.folder,
          title: isNew ? 'Nouveau dossier' : 'Modifier le dossier',
          subtitle: isNew ? 'Pour ranger tes comptes et tes notes' : null,
          submitLabel: isNew ? 'Créer' : 'Enregistrer',
          onSubmit: submit,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: fieldDecoration('Ex. Banque ou Famille', accent: AppColors.folder)
                  .copyWith(errorText: error),
              onChanged: (_) {
                if (error != null) setDialogState(() => error = null);
              },
              onSubmitted: (_) => submit(),
            ),
          ),
        );
      },
    ),
  ).whenComplete(() {
    controller.dispose();
  });
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.18),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
