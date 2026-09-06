import 'package:flutter/material.dart';

import '../../item_visuals.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/dashboard.dart';
import '../vault_session.dart';

/// Santé du coffre : score, fiches à corriger, fiches solides.
class SecurityTab extends StatelessWidget {
  const SecurityTab({super.key, required this.session});

  final VaultSession session;

  @override
  Widget build(BuildContext context) {
    final stats = session.stats;
    final solidPlural = stats.solidCount == 1 ? '' : 's';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const SectionHeader(
          title: 'Sécurité',
          subtitle: 'La santé de ton coffre en un coup d’œil',
          color: AppColors.securityTitle,
        ),
        const SizedBox(height: 20),
        ScoreCard(score: stats.score, hasPasswords: session.passwords.isNotEmpty),
        if (stats.flagged.isNotEmpty) ...[
          const SizedBox(height: 20),
          const WeakPasswordsHeading(),
          const SizedBox(height: 4),
        ],
        ...stats.flagged.map((flagged) => ListTile(
              leading: Icon(entryIcon(flagged.entry), color: AppColors.warning),
              title: Text(flagged.entry.title.isEmpty ? 'Mot de passe' : flagged.entry.title),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: flagged.reasons.map((r) => WeaknessTag(r)).toList()),
              ),
              trailing: IconButton(
                tooltip: 'Modifier',
                onPressed: () => session.onEditEntry(flagged.entry),
                icon: const Icon(Icons.edit_outlined),
              ),
            )),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined, color: AppColors.security),
          title: const Text('Coffre protégé'),
          subtitle: Text('${stats.solidCount} mot$solidPlural de passe solide$solidPlural · masqués par défaut'),
        ),
      ],
    );
  }
}
