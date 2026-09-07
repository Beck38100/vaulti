import 'package:flutter/material.dart';

/// Réglages d'animation communs à toute l'application.
///
/// Tout est regroupé ici pour garder un rythme cohérent : une application
/// consultée vingt fois par jour doit rester nerveuse, donc les durées sont
/// volontairement courtes.
class Motion {
  const Motion._();

  /// Micro-retours : pastilles, icônes de navigation.
  static const quick = Duration(milliseconds: 180);

  /// Apparition d'un élément, changement de contenu.
  static const normal = Duration(milliseconds: 260);

  /// Tracé de l'anneau de score au démarrage.
  static const draw = Duration(milliseconds: 550);

  /// Décélération standard, sans rebond.
  static const curve = Curves.easeOutCubic;

  /// Léger dépassement, pour les surfaces qui surgissent (menu d'ajout).
  static const spring = Curves.easeOutBack;
}

/// Fait apparaître son contenu en fondu, avec une légère montée.
///
/// Utilisé sur les lignes et les cartes : comme l'animation se déclenche à la
/// construction, seul un élément réellement nouveau s'anime — les éléments déjà
/// affichés conservent leur état et restent immobiles.
class AppearIn extends StatelessWidget {
  const AppearIn({super.key, required this.child, this.offset = 12});

  final Widget child;

  /// Distance de la montée, en pixels.
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Motion.normal,
      curve: Motion.curve,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - value) * offset), child: child),
      ),
      child: child,
    );
  }
}

/// Réduit très légèrement une carte tactile pendant l'appui.
///
/// Vient s'ajouter à l'ondulation habituelle de [InkWell] plutôt que la
/// remplacer : passer [onHighlightChanged] de l'InkWell concerné comme second
/// argument du [builder] suffit à brancher l'effet.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.builder});

  final Widget Function(BuildContext context, ValueChanged<bool> onHighlightChanged) builder;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: Motion.quick,
      curve: Motion.curve,
      child: widget.builder(context, (value) => setState(() => _pressed = value)),
    );
  }
}

/// Fait glisser le contenu horizontalement lors d'un changement de dossier.
///
/// [depth] indique le niveau dans l'arborescence : en descendant, le nouveau
/// contenu entre par la droite ; en remontant, il entre par la gauche. C'est le
/// repère habituel de navigation mobile.
class DirectionalSwitcher extends StatelessWidget {
  const DirectionalSwitcher({
    super.key,
    required this.depth,
    required this.previousDepth,
    required this.child,
  });

  final int depth;
  final int previousDepth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final goingDeeper = depth >= previousDepth;
    return AnimatedSwitcher(
      duration: Motion.normal,
      switchInCurve: Motion.curve,
      switchOutCurve: Motion.curve,
      // Seul le contenu entrant est animé : superposer la sortie provoquerait
      // un chevauchement peu lisible dans une liste défilante.
      layoutBuilder: (current, previous) => current ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(goingDeeper ? 0.12 : -0.12, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
