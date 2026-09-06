import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/vault_items.dart';
import '../vault_session.dart';

/// Toutes les fiches de type mot de passe, tous dossiers confondus.
class PasswordsTab extends StatefulWidget {
  const PasswordsTab({super.key, required this.session});

  final VaultSession session;

  @override
  State<PasswordsTab> createState() => _PasswordsTabState();
}

class _PasswordsTabState extends State<PasswordsTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final all = session.passwords;
    final results = VaultSession.search(all, _query);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const SectionHeader(
          title: 'Mots de passe',
          subtitle: 'Toutes tes fiches, au même endroit',
          color: AppColors.password,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          decoration: fieldDecoration('Rechercher une fiche')
              .copyWith(prefixIcon: const Icon(Icons.search, color: AppColors.password)),
        ),
        const SizedBox(height: 16),
        if (all.isEmpty)
          const EmptyState('Aucun mot de passe', hint: 'Ajoute ta première fiche avec le bouton +.', icon: Icons.key_outlined),
        if (all.isNotEmpty && results.isEmpty)
          const EmptyState('Aucune fiche ne correspond', icon: Icons.search_off),
        ...results.map((entry) => EntryRow(
              entry: entry,
              revealed: session.isRevealed(entry),
              actions: session.entryActions(entry),
              folderLabel: session.folderPath(entry.folderId),
            )),
      ],
    );
  }
}
