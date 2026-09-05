import 'package:flutter/material.dart';

import 'theme.dart';

/// Résultat de l'évaluation d'un mot de passe.
class PasswordStrength {
  const PasswordStrength({
    required this.score,
    required this.label,
    required this.color,
    required this.hint,
  });

  /// Score normalisé entre 0 et 1.
  final double score;
  final String label;
  final Color color;
  final String hint;

  /// Un mot de passe est considéré à corriger en dessous de ce seuil.
  static const weakThreshold = .5;

  /// Au-dessus de ce seuil, le mot de passe est considéré comme solide.
  static const solidThreshold = .75;

  bool get isWeak => score < weakThreshold;
  bool get isSolid => score >= solidThreshold;
}

/// Seule et unique règle d'évaluation de la robustesse d'un mot de passe.
/// Toute l'application (score global, jauge, alertes) s'appuie dessus.
PasswordStrength evaluatePassword(String password) {
  if (password.isEmpty) {
    return const PasswordStrength(
      score: 0,
      label: 'Force du mot de passe',
      color: AppColors.strengthEmpty,
      hint: 'Ajoute un mot de passe pour voir sa force',
    );
  }

  var points = 0;
  if (password.length >= 8) points++;
  if (password.length >= 12) points++;
  if (RegExp(r'[a-z]').hasMatch(password)) points++;
  if (RegExp(r'[A-Z]').hasMatch(password)) points++;
  if (RegExp(r'[0-9]').hasMatch(password)) points++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) points++;

  if (password.length < 8) {
    return const PasswordStrength(
      score: .25,
      label: 'Faible',
      color: AppColors.warning,
      hint: 'Utilise au moins 8 caractères',
    );
  }
  if (points <= 3) {
    return const PasswordStrength(
      score: .5,
      label: 'Moyen',
      color: AppColors.strengthMedium,
      hint: 'Ajoute des majuscules, chiffres ou symboles',
    );
  }
  if (points <= 5) {
    return const PasswordStrength(
      score: .75,
      label: 'Bon',
      color: AppColors.strengthGood,
      hint: 'Encore un peu de variété pour le renforcer',
    );
  }
  return const PasswordStrength(
    score: 1,
    label: 'Solide',
    color: AppColors.security,
    hint: 'Bonne longueur et bonne variété',
  );
}
