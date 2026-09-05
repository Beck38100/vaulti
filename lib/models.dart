/// Types de contenu stockés dans le coffre.
enum VaultItemType { password, note }

/// Une fiche du coffre : soit un mot de passe, soit une note libre.
///
/// Les clés JSON sont volontairement conservées telles quelles ('user', 'pass',
/// 'note'...) pour rester compatible avec les coffres déjà enregistrés.
class VaultEntry {
  VaultEntry({
    required this.id,
    required this.type,
    required this.title,
    this.identifier = '',
    this.password = '',
    this.comment = '',
    this.folderId = '',
  });

  String id;
  final VaultItemType type;
  String title;

  /// Pour un mot de passe : l'identifiant (e-mail, pseudo...).
  /// Pour une note : le contenu de la note (format historique).
  String identifier;

  String password;
  String comment;
  String folderId;

  bool get isNote => type == VaultItemType.note;

  /// Contenu affiché quand la fiche est révélée.
  String get revealedContent => isNote ? identifier : password;

  factory VaultEntry.fromJson(Map<String, dynamic> json) {
    return VaultEntry(
      id: (json['id'] ?? '').toString(),
      type: json['type'] == 'note' ? VaultItemType.note : VaultItemType.password,
      title: (json['title'] ?? '').toString(),
      identifier: (json['user'] ?? '').toString(),
      password: (json['pass'] ?? '').toString(),
      comment: (json['note'] ?? '').toString(),
      folderId: (json['folderId'] ?? '').toString(),
    );
  }

  Map<String, String> toJson() => {
        'id': id,
        'type': isNote ? 'note' : 'password',
        'title': title,
        'user': identifier,
        'pass': password,
        'note': comment,
        'folderId': folderId,
      };
}

/// Un dossier, éventuellement imbriqué dans un autre via [parentId].
class VaultFolder {
  VaultFolder({required this.id, required this.title, this.parentId = ''});

  String id;
  String title;
  String parentId;

  bool get isRoot => parentId.isEmpty;

  factory VaultFolder.fromJson(Map<String, dynamic> json) {
    return VaultFolder(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      parentId: (json['parentId'] ?? '').toString(),
    );
  }

  Map<String, String> toJson() => {'id': id, 'title': title, 'parentId': parentId};
}

/// Contenu complet du coffre.
class VaultData {
  VaultData({required this.folders, required this.entries});

  VaultData.empty()
      : folders = [],
        entries = [];

  final List<VaultFolder> folders;
  final List<VaultEntry> entries;

  /// Accepte le format actuel ({folders, entries}) et l'ancien format
  /// (une simple liste de fiches), pour ne perdre aucun coffre existant.
  factory VaultData.fromDecoded(dynamic decoded) {
    if (decoded is List) {
      return VaultData(
        folders: [],
        entries: decoded.map((e) => VaultEntry.fromJson(Map<String, dynamic>.from(e))).toList(),
      )._withRepairedIds();
    }
    if (decoded is Map) {
      return VaultData(
        folders: (decoded['folders'] as List? ?? [])
            .map((e) => VaultFolder.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        entries: (decoded['entries'] as List? ?? [])
            .map((e) => VaultEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      )._withRepairedIds();
    }
    return VaultData.empty();
  }

  /// Les tout premiers coffres pouvaient contenir des fiches sans identifiant.
  /// On leur en attribue un pour éviter que deux fiches se confondent.
  VaultData _withRepairedIds() {
    for (var i = 0; i < folders.length; i++) {
      if (folders[i].id.isEmpty) folders[i].id = 'folder-$i-${DateTime.now().microsecondsSinceEpoch}';
    }
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].id.isEmpty) entries[i].id = 'entry-$i-${DateTime.now().microsecondsSinceEpoch}';
    }
    return this;
  }

  Map<String, dynamic> toJson() => {
        'folders': folders.map((f) => f.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}
