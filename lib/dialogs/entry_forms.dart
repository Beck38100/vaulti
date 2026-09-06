import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'form_shell.dart';

/// Ce que l'utilisateur a saisi dans un formulaire de fiche.
class EntryDraft {
  const EntryDraft({
    required this.title,
    required this.folderId,
    this.identifier = '',
    this.password = '',
    this.comment = '',
  });

  final String title;

  /// Dossier de destination choisi dans le formulaire ('' = racine du coffre).
  final String folderId;

  final String identifier;
  final String password;
  final String comment;
}

/// Champ affichant le dossier de destination et permettant d'en changer.
class _FolderField extends StatelessWidget {
  const _FolderField({required this.path, required this.accent, required this.onTap});

  final String path;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: fieldDecoration('Dossier', accent: accent).copyWith(
          suffixIcon: const Icon(Icons.unfold_more, size: 20),
        ),
        child: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Formulaire d'une fiche mot de passe (création et modification).
Future<EntryDraft?> showPasswordForm(
  BuildContext context, {
  VaultEntry? existing,
  required String initialFolderId,
  required String Function(String? folderId) folderPathOf,
  required Future<String?> Function() chooseFolder,
}) {
  var folderId = initialFolderId;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final userCtrl = TextEditingController(text: existing?.identifier ?? '');
  final passCtrl = TextEditingController(text: existing?.password ?? '');
  final commentCtrl = TextEditingController(text: existing?.comment ?? '');
  var showPassword = false;
  String? titleError;
  String? passwordError;

  return showDialog<EntryDraft>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => VaultFormDialog(
        icon: Icons.key_outlined,
        accent: AppColors.password,
        title: existing == null ? 'Nouvelle fiche' : 'Modifier la fiche',
        submitLabel: 'Enregistrer',
        onSubmit: () {
          final title = titleCtrl.text.trim();
          // Chaque champ manquant est signalé à sa place, plutôt que de laisser
          // le bouton sans effet.
          setDialogState(() {
            titleError = title.isEmpty ? 'Donne un nom à cette fiche.' : null;
            passwordError = passCtrl.text.isEmpty ? 'Saisis le mot de passe à conserver.' : null;
          });
          if (title.isEmpty || passCtrl.text.isEmpty) return;
          closeDialog(
            ctx,
            EntryDraft(
              title: title,
              folderId: folderId,
              identifier: userCtrl.text.trim(),
              password: passCtrl.text,
              comment: commentCtrl.text.trim(),
            ),
          );
        },
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          const FormLabel('Nom de la fiche'),
          TextField(
            controller: titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: fieldDecoration('Ex. Assurance auto', accent: AppColors.password)
                .copyWith(errorText: titleError),
            onChanged: (_) {
              if (titleError != null) setDialogState(() => titleError = null);
            },
          ),
          const SizedBox(height: 16),
          const FormLabel('Dossier'),
          _FolderField(
            path: folderPathOf(folderId.isEmpty ? null : folderId),
            accent: AppColors.password,
            onTap: () async {
              final chosen = await chooseFolder();
              if (chosen != null) setDialogState(() => folderId = chosen);
            },
          ),
          const SizedBox(height: 16),
          const FormLabel('Identifiant'),
          TextField(
            controller: userCtrl,
            decoration: fieldDecoration('E-mail, pseudo, numéro...', accent: AppColors.password),
          ),
          const SizedBox(height: 16),
          const FormLabel('Mot de passe ou code'),
          TextField(
            controller: passCtrl,
            obscureText: !showPassword,
            onChanged: (_) => setDialogState(() => passwordError = null),
            decoration: fieldDecoration('Ce que tu veux garder', accent: AppColors.password).copyWith(
              errorText: passwordError,
              suffixIcon: IconButton(
                tooltip: showPassword ? 'Masquer' : 'Afficher',
                icon: Icon(showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setDialogState(() => showPassword = !showPassword),
              ),
            ),
          ),
          const SizedBox(height: 10),
          PasswordStrengthBar(password: passCtrl.text),
          const SizedBox(height: 16),
          const FormLabel('Commentaire'),
          TextField(
            controller: commentCtrl,
            maxLines: 3,
            decoration: fieldDecoration('Une précision, une date...', accent: AppColors.password),
          ),
        ]),
      ),
    ),
  ).whenComplete(() => disposeAfterFrame([titleCtrl, userCtrl, passCtrl, commentCtrl]));
}

/// Formulaire d'une note (création et modification).
Future<EntryDraft?> showNoteForm(
  BuildContext context, {
  VaultEntry? existing,
  required String initialFolderId,
  required String Function(String? folderId) folderPathOf,
  required Future<String?> Function() chooseFolder,
}) {
  var folderId = initialFolderId;
  final titleCtrl = TextEditingController(text: existing?.title ?? '');
  final contentCtrl = TextEditingController(text: existing?.identifier ?? '');
  String? noteError;

  return showDialog<EntryDraft>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => VaultFormDialog(
        icon: Icons.notes_outlined,
        accent: AppColors.note,
        title: existing == null ? 'Nouvelle note' : 'Modifier la note',
        subtitle: existing == null ? 'Un texte libre, protégé dans le coffre' : null,
        submitLabel: 'Enregistrer',
        onSubmit: () {
          final title = titleCtrl.text.trim();
          final content = contentCtrl.text.trim();
          if (title.isEmpty && content.isEmpty) {
            setDialogState(() => noteError = 'Écris au moins un titre ou du contenu.');
            return;
          }
          closeDialog(
            ctx,
            EntryDraft(
              title: title.isEmpty ? 'Note sans titre' : title,
              folderId: folderId,
              identifier: contentCtrl.text,
            ),
          );
        },
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          const FormLabel('Titre'),
          TextField(
            controller: titleCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: fieldDecoration('Titre de la note', accent: AppColors.note),
          ),
          const SizedBox(height: 16),
          const FormLabel('Dossier'),
          _FolderField(
            path: folderPathOf(folderId.isEmpty ? null : folderId),
            accent: AppColors.note,
            onTap: () async {
              final chosen = await chooseFolder();
              if (chosen != null) setDialogState(() => folderId = chosen);
            },
          ),
          const SizedBox(height: 16),
          const FormLabel('Contenu'),
          TextField(
            controller: contentCtrl,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: fieldDecoration('Écris ce que tu veux garder...', accent: AppColors.note)
                .copyWith(errorText: noteError),
            onChanged: (_) {
              if (noteError != null) setDialogState(() => noteError = null);
            },
          ),
        ]),
      ),
    ),
  ).whenComplete(() => disposeAfterFrame([titleCtrl, contentCtrl]));
}

/// Choix d'un dossier de destination. Renvoie une chaîne vide pour la racine.
///
/// [title] s'adapte au contexte : « Déplacer vers... » pour une fiche déjà
/// rangée, « Choisir un dossier » à la création, où rien n'est encore déplacé.
Future<String?> pickFolder(
  BuildContext context, {
  required List<VaultFolder> folders,
  required String Function(String id) pathOf,
  Set<String> excludedIds = const {},
  String title = 'Déplacer vers...',
}) {
  final choices = folders.where((folder) => !excludedIds.contains(folder.id)).toList();
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      backgroundColor: AppColors.shell,
      shape: dialogShape,
      title: Text(title),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, ''),
          child: const Row(children: [
            Icon(Icons.lock_outline, color: AppColors.signature, size: 20),
            SizedBox(width: 12),
            Text('Mon coffre'),
          ]),
        ),
        ...choices.map((folder) => SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, folder.id),
              child: Row(children: [
                const Icon(Icons.folder_outlined, color: AppColors.folder, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(pathOf(folder.id), overflow: TextOverflow.ellipsis)),
              ]),
            )),
      ],
    ),
  );
}
