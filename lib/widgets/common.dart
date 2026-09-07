import 'package:flutter/material.dart';

import '../password_strength.dart';
import '../theme.dart';
import 'animations.dart';

/// Libellé au-dessus d'un champ de formulaire.
class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      );
}

/// Ligne standard du coffre : icône colorée, titre, sous-titre, actions.
/// Utilisée pour les dossiers comme pour les fiches, afin que tout ait la
/// même hauteur et le même alignement en vue liste.
class VaultRow extends StatelessWidget {
  const VaultRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      builder: (context, onHighlightChanged) => Material(
        color: AppColors.surface,
        shape: cardShape(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: onHighlightChanged,
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
                ]),
              ),
              ?trailing,
            ]),
          ),
        ),
      ),
    );
  }
}

/// Interrupteur à deux positions pour basculer entre vue grille et vue liste.
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({super.key, required this.isGrid, required this.onChanged});

  final bool isGrid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _segment(icon: Icons.grid_view_rounded, tooltip: 'Afficher en grille', selected: isGrid, onTap: () => onChanged(true)),
        _segment(icon: Icons.view_list_rounded, tooltip: 'Afficher en liste', selected: !isGrid, onTap: () => onChanged(false)),
      ]),
    );
  }

  Widget _segment({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.password : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Icon(icon, size: 18, color: selected ? Colors.white : Colors.white38),
          ),
        ),
      ),
    );
  }
}

/// Jauge de robustesse affichée sous un champ mot de passe.
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final result = evaluatePassword(password);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(result.label, style: TextStyle(color: result.color, fontSize: 12, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${(result.score * 100).round()}%', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          duration: Motion.normal,
          curve: Motion.curve,
          tween: Tween(end: result.score),
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 5,
            backgroundColor: AppColors.track,
            valueColor: AlwaysStoppedAnimation(result.color),
          ),
        ),
      ),
      const SizedBox(height: 5),
      Text(result.hint, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
    ]);
  }
}

/// Rappel du code couleur : dossier / mot de passe / note.
class TypeLegend extends StatelessWidget {
  const TypeLegend({super.key});

  @override
  Widget build(BuildContext context) => const Row(children: [
        _TypeDot(color: AppColors.folder, label: 'Dossier'),
        SizedBox(width: 14),
        _TypeDot(color: AppColors.password, label: 'Mot de passe'),
        SizedBox(width: 14),
        _TypeDot(color: AppColors.note, label: 'Note'),
      ]);
}

class _TypeDot extends StatelessWidget {
  const _TypeDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: AppColors.legend, fontSize: 12)),
      ]);
}

/// Pastille indiquant une faiblesse d'un mot de passe.
/// « Faible » et « réutilisé » ont deux couleurs distinctes pour qu'on voie
/// d'un coup d'œil qu'il s'agit de deux problèmes différents.
class WeaknessTag extends StatelessWidget {
  const WeaknessTag(this.label, {super.key});

  static const _colors = {
    'faible': AppColors.warning,
    'réutilisé': AppColors.strengthMedium,
  };

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _colors[label] ?? AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Message affiché quand une liste est vide.
///
/// [hint] sert à guider un premier usage : sans lui, un coffre vide n'indique
/// nulle part comment ajouter quelque chose.
class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.hint, this.icon});

  final String message;
  final String? hint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(children: [
        if (icon != null) ...[
          Icon(icon, size: 40, color: Colors.white24),
          const SizedBox(height: 14),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w600),
        ),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(
            hint!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
          ),
        ],
      ]),
    );
  }
}

/// Titre de section en haut de chaque onglet.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.subtitle, required this.color});

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 6),
      Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
    ]);
  }
}
