import 'models.dart';
import 'password_strength.dart';

/// Une fiche signalée à l'utilisateur.
///
/// Les deux faiblesses sont distinctes et peuvent se cumuler : un mot de passe
/// peut être trop simple, réutilisé ailleurs, ou les deux.
class FlaggedEntry {
  const FlaggedEntry({required this.entry, required this.isWeak, required this.isReused});

  final VaultEntry entry;
  final bool isWeak;
  final bool isReused;

  /// Libellés des faiblesses, dans l'ordre d'affichage.
  List<String> get reasons => [
        if (isWeak) 'faible',
        if (isReused) 'réutilisé',
      ];

  String get reason => reasons.join(', ');
}

/// Indicateurs de santé du coffre, calculés à partir des fiches.
class VaultStats {
  factory VaultStats.from(List<VaultEntry> entries) {
    final passwords = entries.where((e) => !e.isNote).toList();

    if (passwords.isEmpty) {
      return const VaultStats._(score: 0, solidCount: 0, weakCount: 0, flagged: []);
    }

    // Nombre d'utilisations de chaque mot de passe, pour détecter les doublons.
    final usage = <String, int>{};
    for (final entry in passwords) {
      if (entry.password.isEmpty) continue;
      usage[entry.password] = (usage[entry.password] ?? 0) + 1;
    }

    var total = 0.0;
    var solid = 0;
    var weak = 0;
    final flagged = <FlaggedEntry>[];

    for (final entry in passwords) {
      final strength = evaluatePassword(entry.password);
      total += strength.score;
      if (strength.isSolid) solid++;
      if (strength.isWeak) weak++;

      final isReused = entry.password.isNotEmpty && (usage[entry.password] ?? 0) > 1;
      if (strength.isWeak || isReused) {
        flagged.add(FlaggedEntry(entry: entry, isWeak: strength.isWeak, isReused: isReused));
      }
    }

    return VaultStats._(
      score: (total / passwords.length * 100).round(),
      solidCount: solid,
      weakCount: weak,
      flagged: flagged,
    );
  }

  const VaultStats._({
    required this.score,
    required this.solidCount,
    required this.weakCount,
    required this.flagged,
  });

  /// Score global sur 100.
  final int score;
  final int solidCount;
  final int weakCount;

  /// Fiches faibles et/ou réutilisées.
  final List<FlaggedEntry> flagged;
}
