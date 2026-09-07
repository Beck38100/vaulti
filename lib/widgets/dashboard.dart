import 'package:flutter/material.dart';

import '../theme.dart';
import 'animations.dart';

/// Carte du score de sécurité.
///
/// Volontairement épurée : le détail des fiches à corriger est présenté par le
/// bandeau d'alerte juste en dessous, il n'est pas répété ici.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.score,
    this.toFixCount = 0,
    this.onShowIssues,
    this.hasPasswords = true,
  });

  final int score;

  /// Nombre de fiches faibles ou réutilisées ; 0 masque la partie alerte.
  final int toFixCount;
  final VoidCallback? onShowIssues;

  /// Faux tant qu'aucun mot de passe n'existe : afficher 0/100 donnerait
  /// l'impression d'un coffre mal protégé plutôt que simplement vide.
  final bool hasPasswords;

  void _explain(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.shell,
        shape: dialogShape,
        title: const Text('Le score de sécurité'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'C’est la moyenne de la robustesse de tes mots de passe. Chacun est '
            'noté sur sa longueur et sur sa variété de caractères : minuscules, '
            'majuscules, chiffres et symboles.',
            style: TextStyle(color: Colors.grey.shade300, height: 1.4),
          ),
          const SizedBox(height: 14),
          const _ScoreLegendLine(color: AppColors.warning, label: 'Moins de 50 : à renforcer'),
          const _ScoreLegendLine(color: AppColors.strengthMedium, label: 'De 50 à 74 : correct'),
          const _ScoreLegendLine(color: AppColors.security, label: '75 et plus : solide'),
          const SizedBox(height: 14),
          Text(
            'Les notes libres ne sont pas comptées, et un mot de passe réutilisé '
            'est signalé à part même s’il est robuste.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5, height: 1.4),
          ),
        ]),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Compris')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: cardShape(),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(children: [
            SizedBox(
              width: 64,
              height: 64,
              child: hasPasswords
                  ? TweenAnimationBuilder<double>(
                      duration: Motion.draw,
                      curve: Motion.curve,
                      // begin à zéro : l'anneau se trace au premier affichage, puis
                      // les mises à jour repartent de la valeur courante.
                      tween: Tween(begin: 0, end: score / 100),
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 7,
                        backgroundColor: AppColors.track,
                        valueColor: const AlwaysStoppedAnimation(AppColors.password),
                      ),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.track, width: 7),
                      ),
                    ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                if (hasPasswords)
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text('$score', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('/100', style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
                  ])
                else
                  const Text('—', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                  hasPasswords ? 'Score de sécurité' : 'Ajoute un mot de passe pour voir ton score',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                ),
              ]),
            ),
            // Discret : le score n'est pas cliquable, seule cette bulle l'est.
            IconButton(
              tooltip: 'À quoi correspond ce score ?',
              onPressed: () => _explain(context),
              icon: Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
            ),
          ]),
        ),
        // L'alerte fait partie de la carte : un seul bloc plutôt que deux.
        if (toFixCount > 0) _IssuesStrip(count: toFixCount, onTap: onShowIssues),
      ]),
    );
  }
}

/// Bandeau d'alerte intégré au bas de la carte de score.
class _IssuesStrip extends StatelessWidget {
  const _IssuesStrip({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final plural = count > 1 ? 's' : '';
    return Material(
      color: AppColors.warningBackground,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count mot$plural de passe à corriger',
                style: const TextStyle(color: AppColors.warningText, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.warningChevron, size: 18),
          ]),
        ),
      ),
    );
  }
}

class _ScoreLegendLine extends StatelessWidget {
  const _ScoreLegendLine({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade300, fontSize: 13)),
        ]),
      );
}

/// Titre de la liste des fiches à corriger, dans l'onglet Sécurité.
/// Purement informatif : la liste se trouve juste en dessous.
class WeakPasswordsHeading extends StatelessWidget {
  const WeakPasswordsHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(children: [
      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
      SizedBox(width: 10),
      Text(
        'Mots de passe à corriger',
        style: TextStyle(color: AppColors.warningText, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ]);
  }
}
