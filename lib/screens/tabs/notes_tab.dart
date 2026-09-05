import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/vault_items.dart';
import '../vault_session.dart';

/// Les notes libres du coffre.
class NotesTab extends StatefulWidget {
  const NotesTab({super.key, required this.session});

  final VaultSession session;

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
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
    final all = session.notes;
    final results = VaultSession.search(all, _query);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const SectionHeader(
          title: 'Notes',
          subtitle: 'Tes textes libres, protégés dans le coffre',
          color: AppColors.note,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          decoration: fieldDecoration('Rechercher une note')
              .copyWith(prefixIcon: const Icon(Icons.search, color: AppColors.note)),
        ),
        const SizedBox(height: 16),
        if (all.isEmpty)
          const EmptyState('Aucune note', hint: 'Garde ici un code, une adresse, un rappel.', icon: Icons.notes_outlined),
        if (all.isNotEmpty && results.isEmpty)
          const EmptyState('Aucune note ne correspond', icon: Icons.search_off),
        ...results.map((entry) => EntryRow(
              entry: entry,
              revealed: session.isRevealed(entry),
              actions: session.entryActions(entry),
            )),
      ],
    );
  }
}
