import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Fichier « repère » : il prouve qu'un coffre a déjà été enregistré sur cet
/// appareil, indépendamment du stockage sécurisé.
///
/// Si le stockage sécurisé ne contient plus de coffre alors que ce repère
/// existe, le coffre a disparu sans que l'utilisateur l'ait voulu (le plugin
/// du stockage efface ses données en cas d'erreur du magasin de clés) : on le
/// signale au lieu de repartir en silence d'un coffre vide.
///
/// Le fichier ne contient aucune donnée du coffre. Il est volontairement hors du
/// dossier de la sauvegarde (app_flutter/) et absent des règles de sauvegarde
/// Android : après une réinstallation ou un changement de téléphone, il n'existe
/// pas, et le premier lancement reste un premier lancement. Ne jamais l'ajouter
/// à backup_rules.xml ni à data_extraction_rules.xml.
class VaultMarker {
  const VaultMarker([this._directory = _supportDirectory]);

  final Future<Directory> Function() _directory;

  static const fileName = 'vaulti-repere';

  /// files/ sur Android : le dossier des documents (app_flutter/) porte déjà la
  /// sauvegarde chiffrée, on ne les mélange pas.
  static Future<Directory> _supportDirectory() => getApplicationSupportDirectory();

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  /// Vrai si un coffre a déjà été enregistré ici. Une erreur d'accès compte
  /// comme « pas de repère » : on ne bloque jamais l'utilisateur pour un détail.
  Future<bool> exists() async {
    try {
      return await (await _file()).exists();
    } catch (_) {
      return false;
    }
  }

  /// Pose le repère, une fois le coffre enregistré. Silencieux en cas d'échec.
  Future<void> mark() async {
    try {
      final file = await _file();
      if (await file.exists()) return;
      await file.writeAsString('1', flush: true);
    } catch (_) {
      // Le repère est un filet de sécurité : son absence ne doit jamais
      // empêcher d'enregistrer le coffre.
    }
  }
}
