import 'models.dart';

/// Limites de la version gratuite et calcul de l'usage courant.
///
/// Achat unique (pas d'abonnement) : une fois Premium débloqué, plus aucune
/// limite ne s'applique. Chiffres provisoires, à ajuster une fois le prix
/// fixé — c'est le seul endroit à modifier.
class PremiumLimits {
  const PremiumLimits._();

  static const maxFolders = 3;
  static const maxPasswords = 20;
  static const maxNotes = 10;
}

/// Photographie de l'usage du coffre face aux limites de la version gratuite.
class PremiumUsage {
  const PremiumUsage({
    required this.folderCount,
    required this.passwordCount,
    required this.noteCount,
  });

  factory PremiumUsage.from(List<VaultFolder> folders, List<VaultEntry> entries) {
    return PremiumUsage(
      folderCount: folders.length,
      passwordCount: entries.where((e) => !e.isNote).length,
      noteCount: entries.where((e) => e.isNote).length,
    );
  }

  final int folderCount;
  final int passwordCount;
  final int noteCount;

  bool get folderLimitReached => folderCount >= PremiumLimits.maxFolders;
  bool get passwordLimitReached => passwordCount >= PremiumLimits.maxPasswords;
  bool get noteLimitReached => noteCount >= PremiumLimits.maxNotes;
}
