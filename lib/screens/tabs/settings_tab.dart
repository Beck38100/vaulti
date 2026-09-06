import 'package:flutter/material.dart';

import '../../premium.dart';
import '../../theme.dart';
import '../../vault_repository.dart';
import '../../widgets/common.dart';
import '../vault_session.dart';

/// Réglages de l'application : profil et protection du coffre.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.session});

  final VaultSession session;

  Future<void> _chooseAutoLock(BuildContext context) async {
    final chosen = await showDialog<AutoLockDelay>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.shell,
        shape: dialogShape,
        title: const Text('Verrouillage automatique'),
        children: [
          RadioGroup<AutoLockDelay>(
            groupValue: session.autoLockDelay,
            onChanged: (value) => Navigator.pop(ctx, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AutoLockDelay.values
                  .map((delay) => RadioListTile<AutoLockDelay>(
                        value: delay,
                        activeColor: AppColors.signature,
                        title: Text(delay.label),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
    if (chosen != null) session.onAutoLockChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        const SectionHeader(
          title: 'Réglages',
          subtitle: 'Ton profil et la protection du coffre',
          color: AppColors.settings,
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.person_outline, color: AppColors.signature),
          title: const Text('Ton prénom'),
          subtitle: Text(session.userName ?? 'Non renseigné'),
          trailing: const Icon(Icons.edit_outlined, size: 20),
          onTap: session.onRenameUser,
        ),
        const Divider(height: 32, color: AppColors.border),
        const ListTile(
          leading: Icon(Icons.fingerprint, color: AppColors.security),
          title: Text('Empreinte ou code'),
          subtitle: Text('Demandé à l’ouverture du coffre et avant chaque révélation'),
        ),
        ListTile(
          leading: const Icon(Icons.lock_clock_outlined, color: AppColors.signature),
          title: const Text('Verrouillage automatique'),
          subtitle: Text(session.autoLockDelay.label),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => _chooseAutoLock(context),
        ),
        SwitchListTile(
          value: session.screenProtection,
          onChanged: session.onScreenProtectionChanged,
          activeThumbColor: AppColors.signature,
          secondary: const Icon(Icons.screenshot_outlined, color: AppColors.signature),
          title: const Text('Bloquer les captures d’écran'),
          subtitle: const Text('Masque aussi le coffre dans les applis récentes'),
        ),
        const Divider(height: 32, color: AppColors.border),
        ListTile(
          leading: Icon(
            session.hasBackupPassphrase ? Icons.shield_outlined : Icons.shield_outlined,
            color: session.hasBackupPassphrase ? AppColors.security : AppColors.warning,
          ),
          title: const Text('Mot de passe de sauvegarde'),
          subtitle: Text(
            session.hasBackupPassphrase
                ? 'Tes sauvegardes sont protégées'
                : 'À définir : sans lui, aucune sauvegarde n’est possible',
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: session.onConfigureBackup,
        ),
        ListTile(
          leading: const Icon(Icons.upload_file_outlined, color: AppColors.signature),
          title: const Text('Exporter une sauvegarde'),
          subtitle: const Text('Enregistrer une copie chiffrée où tu veux'),
          onTap: session.onExportBackup,
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined, color: AppColors.signature),
          title: const Text('Importer une sauvegarde'),
          subtitle: const Text('Restaurer un coffre depuis un fichier'),
          onTap: session.onImportBackup,
        ),
        const Divider(height: 32, color: AppColors.border),
        _PremiumSection(session: session),
      ],
    );
  }
}

/// Statut Premium et suivi de la version gratuite.
class _PremiumSection extends StatelessWidget {
  const _PremiumSection({required this.session});

  final VaultSession session;

  @override
  Widget build(BuildContext context) {
    if (session.isPremium) {
      return ListTile(
        leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.signature),
        title: const Text('Premium actif'),
        subtitle: const Text('Aucune limite de dossiers, mots de passe ou notes'),
      );
    }

    final usage = session.premiumUsage;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ListTile(
        leading: Icon(Icons.workspace_premium_outlined, color: AppColors.signature),
        title: Text('Version gratuite'),
        subtitle: Text('Achat unique pour lever ces limites, sans abonnement'),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(children: [
          _UsageRow(label: 'Dossiers', color: AppColors.folder, used: usage.folderCount, max: PremiumLimits.maxFolders),
          const SizedBox(height: 12),
          _UsageRow(label: 'Mots de passe', color: AppColors.password, used: usage.passwordCount, max: PremiumLimits.maxPasswords),
          const SizedBox(height: 12),
          _UsageRow(label: 'Notes', color: AppColors.note, used: usage.noteCount, max: PremiumLimits.maxNotes),
        ]),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FilledButton(
          // Simule l'achat en attendant le branchement d'in_app_purchase, une
          // fois les produits créés dans la Play Console.
          onPressed: () => session.onTogglePremiumForTesting(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.signature,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('Passer à Premium (test)'),
        ),
      ),
    ]);
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.color, required this.used, required this.max});

  final String label;
  final Color color;
  final int used;
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : (used / max).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('$used / $max', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: ratio,
          minHeight: 5,
          backgroundColor: AppColors.track,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}
