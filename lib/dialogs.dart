/// Toutes les fenêtres modales de l'application, regroupées par usage.
///
/// Importer ce fichier donne accès à l'ensemble ; chaque famille vit dans son
/// propre fichier sous `lib/dialogs/` :
///
/// - `form_shell.dart`     : l'enveloppe commune aux formulaires
/// - `entry_forms.dart`    : fiches mot de passe, notes, choix du dossier
/// - `creation_menus.dart` : le menu « + » et la création de dossier
/// - `backup_dialogs.dart` : mot de passe de sauvegarde, import
/// - `prompts.dart`        : prénom, confirmation de suppression
/// - `premium_dialogs.dart`: présentation de la version gratuite, paywall
library;

export 'dialogs/backup_dialogs.dart';
export 'dialogs/creation_menus.dart';
export 'dialogs/entry_forms.dart';
export 'dialogs/form_shell.dart';
export 'dialogs/premium_dialogs.dart';
export 'dialogs/prompts.dart';
