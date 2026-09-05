import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'form_shell.dart';

/// Choix du mot de passe qui protégera les sauvegardes.
///
/// Il est saisi deux fois : une faute de frappe rendrait la sauvegarde
/// définitivement illisible, sans aucun moyen de la récupérer.
Future<String?> askNewPassphrase(BuildContext context) {
  final firstCtrl = TextEditingController();
  final secondCtrl = TextEditingController();
  String? error;
  var visible = false;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        void submit() {
          final value = firstCtrl.text;
          if (value.length < 8) {
            setDialogState(() => error = 'Choisis au moins 8 caractères.');
            return;
          }
          if (value != secondCtrl.text) {
            setDialogState(() => error = 'Les deux saisies ne correspondent pas.');
            return;
          }
          Navigator.pop(ctx, value);
        }

        return VaultFormDialog(
          icon: Icons.shield_outlined,
          accent: AppColors.security,
          title: 'Mot de passe de sauvegarde',
          subtitle: 'Il protège tes sauvegardes',
          submitLabel: 'Enregistrer',
          onSubmit: submit,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Note-le ailleurs. Si tu l’oublies, tes sauvegardes seront '
                    'définitivement illisibles : personne ne peut les déverrouiller, '
                    'moi non plus.',
                    style: TextStyle(color: AppColors.warningText, fontSize: 12.5, height: 1.35),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            const FormLabel('Mot de passe'),
            TextField(
              controller: firstCtrl,
              autofocus: true,
              obscureText: !visible,
              decoration: fieldDecoration('Au moins 8 caractères', accent: AppColors.security)
                  .copyWith(
                errorText: error,
                suffixIcon: IconButton(
                  tooltip: visible ? 'Masquer' : 'Afficher',
                  icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setDialogState(() => visible = !visible),
                ),
              ),
              onChanged: (_) {
                if (error != null) setDialogState(() => error = null);
              },
            ),
            const SizedBox(height: 16),
            const FormLabel('Confirmation'),
            TextField(
              controller: secondCtrl,
              obscureText: !visible,
              decoration: fieldDecoration('Saisis-le une seconde fois', accent: AppColors.security),
              onSubmitted: (_) => submit(),
            ),
          ]),
        );
      },
    ),
  );
}

/// Demande le mot de passe de sauvegarde pour ouvrir une sauvegarde existante.
Future<String?> askPassphrase(BuildContext context, {required String message, String? errorText}) {
  final controller = TextEditingController();
  String? error = errorText;
  var visible = false;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        void submit() {
          if (controller.text.isEmpty) {
            setDialogState(() => error = 'Saisis ton mot de passe de sauvegarde.');
            return;
          }
          Navigator.pop(ctx, controller.text);
        }

        return VaultFormDialog(
          icon: Icons.lock_open_outlined,
          accent: AppColors.security,
          title: 'Mot de passe de sauvegarde',
          subtitle: message,
          submitLabel: 'Déverrouiller',
          onSubmit: submit,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: controller,
              autofocus: true,
              obscureText: !visible,
              decoration: fieldDecoration('Ton mot de passe de sauvegarde', accent: AppColors.security)
                  .copyWith(
                errorText: error,
                suffixIcon: IconButton(
                  tooltip: visible ? 'Masquer' : 'Afficher',
                  icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setDialogState(() => visible = !visible),
                ),
              ),
              onChanged: (_) {
                if (error != null) setDialogState(() => error = null);
              },
              onSubmitted: (_) => submit(),
            ),
          ),
        );
      },
    ),
  );
}

/// Que faire d'une sauvegarde importée quand le coffre n'est pas vide.
enum ImportMode { replace, merge }

Future<ImportMode?> askImportMode(BuildContext context, {required int folders, required int entries}) {
  return showDialog<ImportMode>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.shell,
      shape: dialogShape,
      title: const Text('Sauvegarde ouverte'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Elle contient $entries fiche${entries == 1 ? '' : 's'} '
          'et $folders dossier${folders == 1 ? '' : 's'}.',
          style: TextStyle(color: Colors.grey.shade300),
        ),
        const SizedBox(height: 14),
        Text(
          'Ton coffre actuel n’est pas vide : que veux-tu en faire ?',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, ImportMode.merge),
          child: const Text('Ajouter au coffre'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ImportMode.replace),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Tout remplacer'),
        ),
      ],
    ),
  );
}
