import 'package:flutter/material.dart';

import 'models.dart';

/// Palette des cartes de dossier.
///
/// Les dossiers dont le nom n'évoque rien de particulier reçoivent une couleur
/// de cette liste, choisie d'après leur nom : elle reste donc la même à chaque
/// affichage, et deux dossiers voisins ne se ressemblent pas.
const _folderPalette = [
  Color(0xFF24185B), // violet profond
  Color(0xFF54122C), // grenat
  Color(0xFF431B09), // ambre sombre
  Color(0xFF12324A), // bleu nuit
  Color(0xFF1B3A2A), // vert forêt
  Color(0xFF3A1A45), // prune
  Color(0xFF4A2410), // terre cuite
  Color(0xFF13323C), // sarcelle
];

/// Couleur de fond d'une carte de dossier.
Color folderColor(String title) {
  final name = title.toLowerCase();
  // Quelques thèmes courants gardent une couleur reconnaissable.
  if (name.contains('orange')) return _folderPalette[0];
  if (name.contains('mendes') || name.contains('famille')) return _folderPalette[1];
  if (name.contains('banque')) return _folderPalette[2];
  if (name.contains('stream')) return _folderPalette[5];

  if (name.isEmpty) return _folderPalette[3];
  // Somme des caractères : stable, et répartit les noms sur toute la palette.
  final hash = name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return _folderPalette[hash % _folderPalette.length];
}

/// Icône d'un dossier, devinée d'après son nom.
IconData folderIcon(String title) {
  final name = title.toLowerCase();
  if (name.contains('orange') || name.contains('mobile')) return Icons.cell_tower;
  if (name.contains('mendes') || name.contains('famille')) return Icons.groups_outlined;
  if (name.contains('banque')) return Icons.account_balance_outlined;
  if (name.contains('stream')) return Icons.videocam_outlined;
  return Icons.folder_outlined;
}

/// Icône d'une fiche, devinée d'après son intitulé (banque, mail, streaming...).
/// À défaut de catégorie reconnue, on retombe sur la clé.
IconData entryIcon(VaultEntry entry) {
  if (entry.isNote) return Icons.notes_outlined;
  final name = entry.title.toLowerCase();
  if (name.contains('gmail') || name.contains('mail') || name.contains('outlook') || name.contains('yahoo')) {
    return Icons.email_outlined;
  }
  if (name.contains('banque') || name.contains('bank') || name.contains('crédit') || name.contains('credit')) {
    return Icons.account_balance_outlined;
  }
  if (name.contains('netflix') ||
      name.contains('prime') ||
      name.contains('disney') ||
      name.contains('spotify') ||
      name.contains('deezer') ||
      name.contains('stream')) {
    return Icons.play_circle_outline;
  }
  if (name.contains('orange') ||
      name.contains('sfr') ||
      name.contains('bouygues') ||
      name.contains('free') ||
      name.contains('mobile')) {
    return Icons.cell_tower;
  }
  if (name.contains('habitat') || name.contains('immo') || name.contains('logement') || name.contains('loyer')) {
    return Icons.home_outlined;
  }
  if (name.contains('assurance')) return Icons.umbrella_outlined;
  if (name.contains('impot') || name.contains('gouv') || name.contains('caf') || name.contains('ameli') || name.contains('secu')) {
    return Icons.account_balance_outlined;
  }
  if (name.contains('amazon') || name.contains('shop') || name.contains('achat')) return Icons.shopping_bag_outlined;
  if (name.contains('wifi') || name.contains('box') || name.contains('internet') || name.contains('livebox')) {
    return Icons.wifi;
  }
  return Icons.key_rounded;
}
