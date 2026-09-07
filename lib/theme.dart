import 'package:flutter/material.dart';

/// Palette de Vaulti.
///
/// Le violet est la couleur signature de l'application. Chaque type de contenu
/// a ensuite sa propre couleur : dossier = rose, mot de passe = violet,
/// note = orange pastel. Le vert reste réservé à la sécurité (le bouclier).
class AppColors {
  const AppColors._();

  // Couleurs par type de contenu
  static const signature = Color(0xFF9A82FF);
  static const password = Color(0xFF8F78FF);
  static const folder = Color(0xFFE05A8D);
  static const note = Color(0xFFF3A671);
  static const security = Color(0xFF7BE35B);

  // Surfaces
  static const background = Color(0xFF0B0F14);
  static const shell = Color(0xFF171D26);
  static const surface = Color(0xFF11151C);
  static const border = Color(0xFF232B36);
  static const sheet = Color(0xFF1A222B);

  // Champs de saisie : un gris bleuté, plus doux que le noir d'origine.
  static const fieldFill = Color(0xFF1C232E);
  static const fieldBorder = Color(0xFF2C3644);

  // Texte
  static const greeting = Color(0xFFB9AEFF);
  static const headerIcon = Color(0xFFB3A5FF);
  static const onCard = Color(0xFFF0EEE8);
  static const onCardMuted = Color(0xFFC8C7C5);
  static const legend = Color(0xFFBABCC0);

  // Accents fonctionnels
  static const addButton = password; // même violet que l'anneau du score
  static const settings = Color(0xFFC39A5B);
  static const securityTitle = Color(0xFF86C95D);

  // Alerte "à corriger"
  static const warning = Color(0xFFFF7658);
  static const warningBackground = Color(0xFF2A1712);
  static const warningText = Color(0xFFFFB199);
  static const warningChevron = Color(0xFFFF9478);

  // Jauges de force
  static const strengthMedium = Color(0xFFFFB45C);
  static const strengthGood = Color(0xFFB8A9FF);
  static const strengthEmpty = Color(0xFF777A80);
  static const track = Color(0xFF2A2E38);
}

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.password,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}

/// Décoration commune à tous les champs de saisie.
///
/// [accent] colore le champ actif : chaque formulaire reprend ainsi la couleur
/// de son type (rose pour un dossier, violet pour un mot de passe, orange pour
/// une note), ce qui rend les fenêtres de création moins austères.
InputDecoration fieldDecoration(String hint, {Color accent = AppColors.signature}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(22),
    borderSide: const BorderSide(color: AppColors.fieldBorder),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF6B7688)),
    filled: true,
    fillColor: AppColors.fieldFill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: accent, width: 1.6),
    ),
  );
}

/// Forme plate à contour discret, commune aux cartes du coffre (score,
/// fiches, dossiers) : pas de dégradé ni de flou, juste un trait fin pour
/// détacher la carte du fond sans l'alourdir.
ShapeBorder cardShape([double radius = 26]) => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: AppColors.border),
    );

/// Lueur discrète derrière un élément mis en avant (le bouton d'ajout) :
/// la seule touche « glow » reprise de l'inspiration, sans flou généralisé.
List<BoxShadow> glow(Color color) => [
      BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 1),
    ];

/// Message bref, aux couleurs de l'application plutôt qu'au style par défaut.
SnackBar appSnackBar(String message, {bool isWarning = false}) {
  return SnackBar(
    content: Row(children: [
      Icon(
        isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
        color: isWarning ? AppColors.warning : AppColors.security,
        size: 20,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
      ),
    ]),
    backgroundColor: AppColors.surface,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.border),
    ),
    duration: const Duration(seconds: 3),
  );
}

/// Forme arrondie commune aux fenêtres de dialogue.
final dialogShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(26));
