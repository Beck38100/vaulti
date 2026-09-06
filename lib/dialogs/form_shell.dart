import 'package:flutter/material.dart';

import '../theme.dart';

/// Ferme un dialogue de formulaire.
///
/// Sans ce retrait de focus, fermer le clavier et le dialogue dans le même
/// geste fait planter le framework (le champ de texte reste concentré
/// pendant que son AlertDialog se démonte).
void closeDialog<T>(BuildContext context, [T? result]) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.pop(context, result);
}

/// Libère des contrôleurs de texte une fois la fermeture du dialogue
/// retombée, plutôt qu'immédiatement : les disposer pendant que son
/// animation de sortie tient encore le champ de texte fait planter le
/// framework.
void disposeAfterFrame(Iterable<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final controller in controllers) {
      controller.dispose();
    }
  });
}

/// Enveloppe commune aux fenêtres de création et de modification.
///
/// Chaque fenêtre porte la couleur de son type et une icône en médaillon, pour
/// être identifiable d'un coup d'œil plutôt que d'être un simple cadre sombre.
class VaultFormDialog extends StatelessWidget {
  const VaultFormDialog({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    required this.child,
    required this.onSubmit,
    required this.submitLabel,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.shell,
      shape: dialogShape,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(subtitle!, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
              ),
          ]),
        ),
      ]),
      content: SingleChildScrollView(child: child),
      actions: [
        TextButton(
          onPressed: () => closeDialog(context),
          child: Text('Annuler', style: TextStyle(color: Colors.grey.shade400)),
        ),
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(submitLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
