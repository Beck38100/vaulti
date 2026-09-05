import 'package:flutter/material.dart';

import '../theme.dart';

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
          Navigator.pop(ctx, name);
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
                  onPressed: () => Navigator.pop(ctx),
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
  ).whenComplete(() {
    controller.dispose();
  });
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
