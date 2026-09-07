import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:cryptography/cryptography.dart';
import 'package:file_picker/file_picker.dart';

import '../auth_service.dart';
import '../backup_crypto.dart';
import '../backup_service.dart';
import '../dialogs.dart';
import '../models.dart';
import '../premium.dart';
import '../screen_security.dart';
import '../secure_clipboard.dart';
import '../theme.dart';
import '../vault_repository.dart';
import '../vault_stats.dart';
import '../widgets/shell.dart';
import 'lock_screen.dart';
import 'tabs/folders_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/passwords_tab.dart';
import 'tabs/security_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/vault_tab.dart';
import 'vault_session.dart';

/// Écran principal : conserve l'état du coffre et orchestre les six onglets.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _repository = const VaultRepository();
  final _auth = AuthService();
  final _screenSecurity = const ScreenSecurity();
  final _clipboard = const SecureClipboard();
  final _backup = const BackupService();
  final _vaultSearchController = TextEditingController();

  List<VaultFolder> _folders = [];
  List<VaultEntry> _entries = [];
  final Set<String> _revealedIds = {};

  String? _userName;
  bool _isPremium = false;
  int _selectedTab = 0;
  String? _currentFolderId;

  AutoLockDelay _autoLockDelay = AutoLockDelay.defaultDelay;
  bool _screenProtection = true;

  /// Clé de sauvegarde en mémoire ; absente tant qu'aucune phrase secrète
  /// n'a été choisie, ou sur un appareil neuf avant restauration.
  SecretKey? _backupKey;
  List<int>? _backupSalt;

  /// Instant où l'application est passée en arrière-plan.
  DateTime? _leftAt;

  /// Une demande d'empreinte met elle-même l'application en arrière-plan.
  /// Sans ce compteur, le verrouillage automatique se déclencherait pendant
  /// l'authentification et l'application boucherait indéfiniment.
  int _authInProgress = 0;

  Timer? _revealTimer;
  Timer? _clipboardTimer;

  /// Échéance d'effacement du dernier mot de passe copié.
  DateTime? _clipboardDueAt;

  /// Un mot de passe révélé est remasqué au bout de ce délai.
  static const _revealDuration = Duration(seconds: 30);

  /// Le presse-papiers est vidé après ce délai, pour qu'un mot de passe copié
  /// ne reste pas lisible par les autres applications.
  static const _clipboardDuration = Duration(seconds: 45);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserName();
    _loadSecuritySettings();
    _loadPremiumStatus();
    _openVault();
  }

  /// Le coffre local doit être lu avant la clé de sauvegarde : c'est son
  /// contenu qui décide s'il faut proposer une restauration. Lancés en
  /// parallèle, ces deux chargements pourraient réclamer le mot de passe de
  /// sauvegarde alors que le coffre est déjà rempli.
  Future<void> _openVault() async {
    await _loadVault();
    await _loadBackupKey();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _revealTimer?.cancel();
    _clipboardTimer?.cancel();
    _vaultSearchController.dispose();
    super.dispose();
  }

  // --- Sécurité -----------------------------------------------------------

  Future<void> _loadSecuritySettings() async {
    final delay = await _repository.readAutoLockDelay();
    final protection = await _repository.readScreenProtection();
    if (!mounted) return;
    setState(() {
      _autoLockDelay = delay;
      _screenProtection = protection;
    });
    await _screenSecurity.setEnabled(protection);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pendant une demande d'empreinte, l'application passe en arrière-plan
    // sans que l'utilisateur ne l'ait quittée : on ignore ces transitions.
    if (_authInProgress > 0) return;

    if (state == AppLifecycleState.inactive) {
      // Simple passage au second plan (volet de notifications, appel...) :
      // on masque les mots de passe affichés sans armer le verrouillage,
      // sinon dérouler ses notifications suffirait à fermer le coffre.
      _hideRevealed();
    } else if (state == AppLifecycleState.paused) {
      _leftAt = DateTime.now();
      _hideRevealed();
    } else if (state == AppLifecycleState.resumed) {
      _wipeClipboardIfDue();
      final leftAt = _leftAt;
      _leftAt = null;
      if (leftAt == null || !_autoLockDelay.isEnabled) return;
      if (DateTime.now().difference(leftAt).inSeconds >= _autoLockDelay.seconds) {
        _lock();
      }
    }
  }

  /// Exécute une authentification en signalant qu'elle est en cours, pour que
  /// le verrouillage automatique ne se déclenche pas par-dessus.
  Future<AuthResult> _authenticate(String reason) async {
    _authInProgress++;
    try {
      return await _auth.authenticate(reason);
    } finally {
      _authInProgress--;
      _leftAt = null;
    }
  }

  void _hideRevealed() {
    _revealTimer?.cancel();
    if (_revealedIds.isEmpty) return;
    setState(_revealedIds.clear);
  }

  /// Sur un appareil neuf, Android a pu restaurer le fichier chiffré avant que
  /// l'application ne s'ouvre : on propose alors de récupérer le coffre.
  Future<void> _offerRestoreIfAvailable() async {
    final envelope = await _backup.readEnvelope();
    if (envelope == null || !mounted) return;
    if (_entries.isNotEmpty || _folders.isNotEmpty) return; // coffre déjà rempli

    await _restoreFrom(envelope, message: 'Une sauvegarde a été retrouvée sur cet appareil.');
  }

  /// Demande la phrase et restaure le coffre. Réessaie tant que la phrase est
  /// refusée, sauf si l'utilisateur renonce.
  Future<bool> _restoreFrom(String envelope, {required String message}) async {
    String? errorText;
    while (true) {
      if (!mounted) return false;
      final passphrase = await askPassphrase(context, message: message, errorText: errorText);
      if (passphrase == null || !mounted) return false;

      try {
        final restored = await _backup.restore(envelope, passphrase);
        if (!mounted) return false;
        setState(() {
          _folders = restored.data.folders;
          _entries = restored.data.entries;
          _backupKey = restored.key;
          _backupSalt = restored.salt;
        });
        await _repository.saveVault(restored.data);
        await _repository.saveBackupKey(await restored.key.extractBytes(), restored.salt);
        if (!mounted) return true;
        _showMessage('Coffre restauré : ${restored.data.entries.length} fiche(s)');
        return true;
      } on BackupDecryptException catch (error) {
        errorText = error.reason;
      }
    }
  }

  /// Choix (ou remplacement) de la phrase secrète de sauvegarde.
  Future<void> _configureBackupPassphrase() async {
    final passphrase = await askNewPassphrase(context);
    if (passphrase == null || !mounted) return;

    final prepared = await _backup.prepareKey(passphrase);
    if (!mounted) return;
    setState(() {
      _backupKey = prepared.key;
      _backupSalt = prepared.salt;
    });
    await _repository.saveBackupKey(await prepared.key.extractBytes(), prepared.salt);
    await _refreshBackup(VaultData(folders: _folders, entries: _entries));
    if (!mounted) return;
    _showMessage('Sauvegarde protégée. Note bien ton mot de passe.');
  }

  /// Enregistre une copie de la sauvegarde à l'endroit choisi par l'utilisateur.
  Future<void> _exportBackup() async {
    if (_backupKey == null) {
      await _configureBackupPassphrase();
      if (_backupKey == null) return;
    }
    final envelope = await _backup.readEnvelope();
    if (envelope == null || !mounted) {
      if (mounted) _showMessage('Aucune sauvegarde à exporter pour le moment.', isWarning: true);
      return;
    }

    try {
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Enregistrer la sauvegarde',
        fileName: _backup.suggestedExportName(),
        bytes: utf8.encode(envelope),
        mimeType: 'text/plain',
      );
      if (!mounted) return;
      _showMessage(saved == null ? 'Export annulé' : 'Sauvegarde exportée');
    } catch (error) {
      if (mounted) _showMessage('Export impossible : $error', isWarning: true);
    }
  }

  /// Ouvre un fichier de sauvegarde et propose de l'ajouter ou de tout remplacer.
  Future<void> _importBackup() async {
    final selection = await FilePicker.pickFiles();
    if (selection.isEmpty || !mounted) return;

    final String envelope;
    try {
      envelope = utf8.decode(await selection.first.readAsBytes(), allowMalformed: true);
    } catch (error) {
      if (mounted) _showMessage('Fichier illisible.', isWarning: true);
      return;
    }
    if (!mounted) return;
    final vaultIsEmpty = _entries.isEmpty && _folders.isEmpty;
    if (vaultIsEmpty) {
      await _restoreFrom(envelope, message: 'Saisis le mot de passe qui protège ce fichier.');
      return;
    }

    // Coffre non vide : on déchiffre d'abord pour annoncer ce que contient le
    // fichier, avant de demander quoi en faire.
    String? errorText;
    while (true) {
      if (!mounted) return;
      final passphrase = await askPassphrase(
        context,
        message: 'Saisis le mot de passe qui protège ce fichier.',
        errorText: errorText,
      );
      if (passphrase == null || !mounted) return;

      try {
        final opened = await _backup.restore(envelope, passphrase);
        if (!mounted) return;
        final mode = await askImportMode(
          context,
          folders: opened.data.folders.length,
          entries: opened.data.entries.length,
        );
        if (mode == null || !mounted) return;
        await _applyImport(opened.data, mode);
        return;
      } on BackupDecryptException catch (error) {
        errorText = error.reason;
      }
    }
  }

  Future<void> _applyImport(VaultData imported, ImportMode mode) async {
    setState(() {
      if (mode == ImportMode.replace) {
        _folders = imported.folders;
        _entries = imported.entries;
      } else {
        // Fusion : on n'ajoute que ce qui n'existe pas déjà, pour ne jamais
        // écraser une fiche que l'utilisateur aurait modifiée depuis.
        final knownFolders = _folders.map((f) => f.id).toSet();
        final knownEntries = _entries.map((e) => e.id).toSet();
        _folders.addAll(imported.folders.where((f) => !knownFolders.contains(f.id)));
        _entries.addAll(imported.entries.where((e) => !knownEntries.contains(e.id)));
      }
    });
    await _save();
    if (!mounted) return;
    _showMessage(mode == ImportMode.replace ? 'Coffre remplacé' : 'Sauvegarde ajoutée au coffre');
  }

  // --- Chargement et sauvegarde ------------------------------------------

  Future<void> _loadVault() async {
    final data = await _repository.loadVault();
    if (!mounted) return;
    setState(() {
      _folders = data.folders;
      _entries = data.entries;
    });
  }

  Future<void> _loadUserName() async {
    final name = await _repository.readUserName();
    if (!mounted) return;
    if (name != null) {
      setState(() => _userName = name);
      return;
    }
    // Premier lancement : la version gratuite se présente juste après le
    // déverrouillage, avant de demander le prénom.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showFreeTierIntro(context);
      if (mounted) _askUserName(firstLaunch: true);
    });
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await _repository.readIsPremium();
    if (!mounted) return;
    setState(() => _isPremium = isPremium);
  }

  Future<void> _setPremiumForTesting(bool isPremium) async {
    setState(() => _isPremium = isPremium);
    await _repository.saveIsPremium(isPremium);
    if (!mounted) return;
    _showMessage(isPremium ? 'Premium activé (test) : plus aucune limite.' : 'Premium désactivé (test).');
  }

  /// Bloque la création avec un paywall si la limite gratuite est atteinte.
  /// Retourne `true` si la création peut se poursuivre.
  Future<bool> _checkPremiumLimit({required bool limitReached, required String limitLabel}) async {
    if (_isPremium || !limitReached) return true;
    final wantsPremium = await showPaywallDialog(context, limitLabel: limitLabel);
    if (wantsPremium && mounted) setState(() => _selectedTab = 5);
    return false;
  }

  Future<void> _askUserName({bool firstLaunch = false}) async {
    final name = await askUserName(
      context,
      initialValue: firstLaunch ? null : _userName,
      dismissible: !firstLaunch,
    );
    if (name == null || !mounted) return;
    await _repository.saveUserName(name);
    if (!mounted) return;
    setState(() => _userName = name);
  }

  Future<void> _save() async {
    final data = VaultData(folders: _folders, entries: _entries);
    await _repository.saveVault(data);
    await _refreshBackup(data);
  }

  /// Met à jour la sauvegarde chiffrée après chaque modification.
  /// Sans phrase secrète configurée, il n'y a rien à écrire.
  Future<void> _refreshBackup(VaultData data) async {
    final key = _backupKey;
    final salt = _backupSalt;
    if (key == null || salt == null) return;
    try {
      await _backup.write(data, key, salt);
    } catch (_) {
      // Un échec d'écriture ne doit jamais empêcher d'enregistrer le coffre
      // lui-même, qui reste la source de vérité sur l'appareil.
    }
  }

  Future<void> _loadBackupKey() async {
    final stored = await _repository.readBackupKey();
    if (stored == null || !mounted) {
      // Aucune clé locale : soit rien n'est configuré, soit l'appareil est
      // neuf et une sauvegarde restaurée par Android attend une phrase.
      if (mounted) await _offerRestoreIfAvailable();
      return;
    }
    setState(() {
      _backupKey = SecretKey(stored.key);
      _backupSalt = stored.salt;
    });
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // --- Fiches -------------------------------------------------------------

  Future<void> _toggleReveal(VaultEntry entry) async {
    if (_revealedIds.contains(entry.id)) {
      setState(() => _revealedIds.remove(entry.id));
      return;
    }
    final result = await _authenticate('Authentifie-toi pour révéler ce contenu');
    if (!mounted) return;
    if (result.granted) {
      setState(() => _revealedIds.add(entry.id));
      // Remasquage automatique : un mot de passe affiché ne doit pas le rester
      // si le téléphone est posé sur une table.
      _revealTimer?.cancel();
      _revealTimer = Timer(_revealDuration, () {
        if (mounted) setState(_revealedIds.clear);
      });
    } else if (result.error != null) {
      _showMessage('Authentification indisponible sur cet appareil.');
    }
  }

  Future<void> _copyPassword(VaultEntry entry) async {
    final result = await _authenticate('Authentifie-toi pour copier ce mot de passe');
    if (!mounted || !result.granted) return;
    await _clipboard.copy(entry.password);
    if (!mounted) return;
    _scheduleClipboardWipe();
    _showMessage('Copié — le presse-papiers sera vidé dans 45 secondes.');
  }

  /// Vide le presse-papiers après un délai, sauf si l'utilisateur a copié
  /// autre chose entre-temps : on ne veut pas effacer son contenu à lui.
  void _scheduleClipboardWipe() {
    _clipboardTimer?.cancel();
    _clipboardDueAt = DateTime.now().add(_clipboardDuration);
    _clipboardTimer = Timer(_clipboardDuration, _wipeClipboard);
  }

  /// Android interdit à une application en arrière-plan de toucher au
  /// presse-papiers : si le délai expire pendant que l'utilisateur est ailleurs
  /// (le cas normal, il va coller son mot de passe), l'effacement échoue
  /// silencieusement. On réessaie donc au retour dans l'application.
  void _wipeClipboardIfDue() {
    final dueAt = _clipboardDueAt;
    if (dueAt != null && DateTime.now().isAfter(dueAt)) _wipeClipboard();
  }

  Future<void> _wipeClipboard() async {
    if (_clipboardDueAt == null) return;
    await _clipboard.clearIfOurs();
    _clipboardDueAt = null;
  }

  Future<void> _createEntry(AddChoice choice) async {
    final isNote = choice == AddChoice.note;
    final usage = PremiumUsage.from(_folders, _entries);
    final allowed = await _checkPremiumLimit(
      limitReached: isNote ? usage.noteLimitReached : usage.passwordLimitReached,
      limitLabel: isNote ? '${PremiumLimits.maxNotes} notes' : '${PremiumLimits.maxPasswords} mots de passe',
    );
    if (!allowed || !mounted) return;

    // Le dossier ouvert sert de proposition, mais reste modifiable dans le
    // formulaire : on peut ranger une fiche n'importe où sans la déplacer après.
    final startFolder = _currentFolderId ?? '';
    final draft = isNote
        ? await showNoteForm(
            context,
            initialFolderId: startFolder,
            folderPathOf: _sessionFolderPath,
            chooseFolder: _pickDestinationForCreation,
          )
        : await showPasswordForm(
            context,
            initialFolderId: startFolder,
            folderPathOf: _sessionFolderPath,
            chooseFolder: _pickDestinationForCreation,
          );
    if (draft == null || !mounted) return;

    setState(() {
      _entries.add(VaultEntry(
        id: _newId(),
        type: isNote ? VaultItemType.note : VaultItemType.password,
        title: draft.title,
        identifier: draft.identifier,
        password: draft.password,
        comment: draft.comment,
        folderId: draft.folderId,
      ));
    });
    await _save();
    if (!mounted) return;
    _showMessage(isNote ? 'Note enregistrée' : 'Fiche enregistrée');
  }

  Future<void> _editEntry(VaultEntry entry) async {
    final draft = entry.isNote
        ? await showNoteForm(
            context,
            existing: entry,
            initialFolderId: entry.folderId,
            folderPathOf: _sessionFolderPath,
            chooseFolder: _pickDestination,
          )
        : await showPasswordForm(
            context,
            existing: entry,
            initialFolderId: entry.folderId,
            folderPathOf: _sessionFolderPath,
            chooseFolder: _pickDestination,
          );
    if (draft == null || !mounted) return;

    setState(() {
      entry.title = draft.title;
      entry.folderId = draft.folderId;
      entry.identifier = draft.identifier;
      if (!entry.isNote) {
        entry.password = draft.password;
        entry.comment = draft.comment;
      }
    });
    await _save();
    if (!mounted) return;
    _showMessage('Modifications enregistrées');
  }

  Future<void> _moveEntry(VaultEntry entry) async {
    final folderId = await _pickDestination();
    if (folderId == null || !mounted) return;
    setState(() => entry.folderId = folderId);
    await _save();
    if (!mounted) return;
    _showMessage('Déplacé vers ${_sessionFolderPath(folderId.isEmpty ? null : folderId)}');
  }

  Future<bool> _deleteEntry(VaultEntry entry) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Supprimer ${entry.title} ?',
      message: 'Cette fiche sera définitivement supprimée. Cette action est irréversible.',
    );
    if (!confirmed || !mounted) return false;
    final title = entry.title;
    setState(() {
      _entries.removeWhere((item) => item.id == entry.id);
      _revealedIds.remove(entry.id);
    });
    await _save();
    if (!mounted) return true;
    _showMessage('$title supprimé');
    return true;
  }

  // --- Dossiers -----------------------------------------------------------

  Future<void> _createFolder() async {
    final usage = PremiumUsage.from(_folders, _entries);
    final allowed = await _checkPremiumLimit(
      limitReached: usage.folderLimitReached,
      limitLabel: '${PremiumLimits.maxFolders} dossiers',
    );
    if (!allowed || !mounted) return;

    final title = await askFolderName(context);
    if (title == null || !mounted) return;

    final folderId = _newId();
    setState(() {
      _folders.add(VaultFolder(id: folderId, title: title, parentId: _currentFolderId ?? ''));
      _currentFolderId = folderId;
      _selectedTab = 0;
    });
    await _save();
    if (!mounted) return;

    final next = await showFolderNextStep(context);
    if (next == null || !mounted) return;
    await _createEntry(next);
  }

  Future<void> _editFolder(VaultFolder folder) async {
    final title = await askFolderName(context, initialValue: folder.title);
    if (title == null || !mounted) return;
    setState(() => folder.title = title);
    await _save();
  }

  Future<void> _moveFolder(VaultFolder folder) async {
    // On empêche de déplacer un dossier dans l'un de ses propres sous-dossiers.
    final blocked = _descendantIds(folder.id)..add(folder.id);
    final folderId = await _pickDestination(excludedIds: blocked);
    if (folderId == null || !mounted) return;
    setState(() => folder.parentId = folderId);
    await _save();
  }

  Future<bool> _deleteFolder(VaultFolder folder) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Supprimer ${folder.title} ?',
      message: 'Les sous-dossiers et les éléments contenus seront également supprimés. Cette action est irréversible.',
    );
    if (!confirmed || !mounted) return false;

    final removed = _descendantIds(folder.id)..add(folder.id);
    final title = folder.title;
    setState(() {
      _folders.removeWhere((item) => removed.contains(item.id));
      _entries.removeWhere((item) => removed.contains(item.folderId));
      if (removed.contains(_currentFolderId)) _currentFolderId = null;
    });
    await _save();
    if (!mounted) return true;
    _showMessage('Dossier $title supprimé');
    return true;
  }

  /// Identifiants de tous les dossiers contenus, à n'importe quelle profondeur.
  Set<String> _descendantIds(String folderId) {
    final found = <String>{folderId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final folder in _folders) {
        if (found.contains(folder.parentId) && found.add(folder.id)) changed = true;
      }
    }
    return found..remove(folderId);
  }

  Future<String?> _pickDestination({Set<String> excludedIds = const {}, String? title}) {
    return pickFolder(
      context,
      folders: _folders,
      excludedIds: excludedIds,
      pathOf: _sessionFolderPath,
      title: title ?? 'Déplacer vers...',
    );
  }

  /// Choix du dossier lors de la création : rien n'est encore rangé, donc pas
  /// question de « déplacer ».
  Future<String?> _pickDestinationForCreation() => _pickDestination(title: 'Choisir un dossier');

  String _sessionFolderPath(String? folderId) => _buildSession().folderPath(folderId);

  // --- Divers -------------------------------------------------------------

  void _showMessage(String message, {bool isWarning = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(appSnackBar(message, isWarning: isWarning));
  }

  Future<void> _openAddMenu() async {
    final choice = await showAddMenu(context);
    if (choice == null || !mounted) return;
    if (choice == AddChoice.folder) {
      await _createFolder();
    } else {
      await _createEntry(choice);
    }
  }

  void _lock() {
    _revealTimer?.cancel();
    _revealedIds.clear();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LockScreen()));
  }

  Future<void> _setAutoLockDelay(AutoLockDelay delay) async {
    setState(() => _autoLockDelay = delay);
    await _repository.saveAutoLockDelay(delay);
  }

  Future<void> _setScreenProtection(bool enabled) async {
    setState(() => _screenProtection = enabled);
    await _repository.saveScreenProtection(enabled);
    await _screenSecurity.setEnabled(enabled);
  }

  /// Appui sur une icône de la barre du bas.
  /// Revenir sur « Coffre » ou taper sur « Dossiers » ramène toujours à la
  /// racine, sans avoir à remonter les dossiers un par un. Un dossier ouvert
  /// depuis une recherche (qui passe par onGoToTab, pas par ici) reste lui
  /// affiché tel quel.
  void _onNavTap(int index) {
    if (index == 0) _vaultSearchController.clear();
    setState(() {
      _selectedTab = index;
      if (index == 0 || index == 3) _currentFolderId = null;
    });
  }

  VaultSession _buildSession() {
    return VaultSession(
      folders: _folders,
      entries: _entries,
      stats: VaultStats.from(_entries),
      revealedIds: _revealedIds,
      userName: _userName,
      currentFolderId: _currentFolderId,
      onToggleReveal: _toggleReveal,
      onCopyPassword: _copyPassword,
      onEditEntry: _editEntry,
      onMoveEntry: _moveEntry,
      onDeleteEntry: _deleteEntry,
      onEditFolder: _editFolder,
      onMoveFolder: _moveFolder,
      onDeleteFolder: _deleteFolder,
      onOpenFolder: (folderId) => setState(() => _currentFolderId = folderId),
      onAddFolder: _createFolder,
      onGoToTab: (index) => setState(() => _selectedTab = index),
      onRenameUser: _askUserName,
      autoLockDelay: _autoLockDelay,
      onAutoLockChanged: _setAutoLockDelay,
      screenProtection: _screenProtection,
      onScreenProtectionChanged: _setScreenProtection,
      hasBackupPassphrase: _backupKey != null,
      onConfigureBackup: _configureBackupPassphrase,
      onExportBackup: _exportBackup,
      onImportBackup: _importBackup,
      isPremium: _isPremium,
      onTogglePremiumForTesting: _setPremiumForTesting,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = _buildSession();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          // Material (et non un simple Container décoré) : les ListTile et les
          // effets de contact peignent leur fond sur le Material le plus proche.
          child: Material(
            color: AppColors.shell,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppHeader(onLock: _lock),
              // IndexedStack conserve chaque onglet en mémoire : la position de
              // défilement et les recherches en cours survivent au changement
              // d'onglet, ce qui rend la navigation immédiate.
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    VaultTab(session: session, searchController: _vaultSearchController),
                    PasswordsTab(session: session),
                    NotesTab(session: session),
                    FoldersTab(session: session),
                    SecurityTab(session: session),
                    SettingsTab(session: session),
                  ],
                ),
              ),
              BottomNavBar(
                selectedIndex: _selectedTab,
                onSelect: _onNavTap,
                onAdd: _openAddMenu,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
