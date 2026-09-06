import 'package:flutter/material.dart';

import '../premium.dart';
import '../theme.dart';

/// Présentée une fois, au tout premier lancement, juste après le
/// déverrouillage et avant de demander le prénom.
Future<void> showFreeTierIntro(BuildContext context) {
  return showDialog<void>(
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
            color: AppColors.signature.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.workspace_premium_outlined, color: AppColors.signature, size: 24),
        ),
        const SizedBox(height: 18),
        const Text('Version gratuite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'Tu peux créer jusqu’à ${PremiumLimits.maxFolders} dossiers, '
          '${PremiumLimits.maxPasswords} mots de passe et ${PremiumLimits.maxNotes} notes gratuitement. '
          'Au-delà, passe en Premium (achat unique, sans abonnement) pour lever toutes les limites.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13.5, height: 1.4),
        ),
      ]),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.signature,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Compris'),
        ),
      ],
    ),
  );
}

/// Affichée quand une limite de la version gratuite est atteinte.
/// Retourne `true` si l'utilisateur veut voir les options Premium.
Future<bool> showPaywallDialog(BuildContext context, {required String limitLabel}) async {
  final result = await showDialog<bool>(
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
            color: AppColors.signature.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.workspace_premium_outlined, color: AppColors.signature, size: 24),
        ),
        const SizedBox(height: 18),
        const Text('Limite atteinte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'La version gratuite est limitée à $limitLabel. '
          'Passe en Premium (achat unique) pour continuer à en ajouter.',
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
          child: const Text('Plus tard', style: TextStyle(color: Colors.white)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.signature,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Voir Premium', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return result ?? false;
}
