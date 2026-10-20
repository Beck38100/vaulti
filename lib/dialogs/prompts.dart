import 'package:flutter/material.dart';

import '../theme.dart';
import 'form_shell.dart';

/// Demande le prénom de l'utilisateur.
/// Quand [dismissible] est faux, la fenêtre ne peut pas être fermée sans réponse
/// (premier lancement de l'application).
Future<String?> askUserName(
  BuildContext context, {
  String? initialValue,
  bool dismissible = true,
}) {
  final controller = TextEditingController(text: initialValue ?? '');
  String? error;

  return showDialog<String>(
    context: context,
    barrierDismissible: dismissible,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        void submit() {
          final name = controller.text.trim();
          if (name.isEmpty) {
            setDialogState(() => error = 'Indique ton prénom pour continuer.');
            return;
          }
          closeDialog(ctx, name);
        }

        return PopScope(
          canPop: dismissible,
          child: AlertDialog(
            backgroundColor: AppColors.shell,
            shape: dialogShape,
            title: Text(initialValue == null ? 'Bienvenue' : 'Ton prénom'),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(initialValue == null ? 'Comment tu t’appelles ?' : 'Ce prénom s’affiche sur l’accueil.'),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: fieldDecoration('Ton prénom').copyWith(errorText: error),
                onChanged: (_) {
                  if (error != null) setDialogState(() => error = null);
                },
                onSubmitted: (_) => submit(),
              ),
            ]),
            actions: [
              if (dismissible)
                TextButton(
                  onPressed: () => closeDialog(ctx),
                  child: Text('Annuler', style: TextStyle(color: Colors.grey.shade400)),
                ),
              FilledButton(
                onPressed: submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.signature,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(initialValue == null ? 'Continuer' : 'Enregistrer'),
              ),
            ],
          ),
        );
      },
    ),
  ).whenComplete(() => disposeAfterFrame([controller]));
}

/// Ce que l'utilisateur décide quand le coffre enregistré est illisible.
enum VaultRecovery { retry, restoreBackup, startEmpty }

/// Annonce que le coffre n'a pas pu être lu et laisse l'utilisateur décider.
/// La fenêtre ne se ferme pas sans réponse : tant qu'il n'a pas choisi, rien
/// n'est écrit par-dessus le coffre existant.
Future<VaultRecovery> askVaultRecovery(BuildContext context) async {
  final choice = await showDialog<VaultRecovery>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.shell,
        shape: dialogShape,
        title: const Text('Coffre illisible'),
        content: Text(
          'Vaulti n’arrive pas à lire ou à retrouver ton coffre sur ce téléphone. '
          'Il n’écrit rien tant que tu n’as pas choisi.\n\n'
          'Tu peux réessayer, importer une sauvegarde chiffrée, ou repartir d’un coffre vide : '
          'le coffre illisible serait alors remplacé.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13.5, height: 1.4),
        ),
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          TextButton(
            onPressed: () => closeDialog(ctx, VaultRecovery.startEmpty),
            child: Text('Repartir d’un coffre vide', style: TextStyle(color: Colors.grey.shade400)),
          ),
          TextButton(
            onPressed: () => closeDialog(ctx, VaultRecovery.restoreBackup),
            child: const Text('Importer une sauvegarde'),
          ),
          FilledButton(
            onPressed: () => closeDialog(ctx, VaultRecovery.retry),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.signature,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
  // Sans réponse (ne devrait pas arriver), on réessaie : le choix le moins destructeur.
  return choice ?? VaultRecovery.retry;
}

/// Confirmation avant une suppression.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.shell,
      shape: dialogShape,
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.warning, size: 24),
        ),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13.5, height: 1.4),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          child: const Text('Annuler', style: TextStyle(color: Colors.white)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
