import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Erreur de déchiffrement d'une sauvegarde.
class BackupDecryptException implements Exception {
  const BackupDecryptException(this.reason);

  /// Message destiné à l'utilisateur.
  final String reason;

  @override
  String toString() => reason;
}

/// Chiffrement des sauvegardes du coffre par phrase secrète.
///
/// Le format retenu est délibérément classique :
/// - la clé est dérivée de la phrase par PBKDF2-HMAC-SHA256, avec un sel
///   aléatoire propre à chaque sauvegarde ;
/// - le contenu est chiffré par AES-GCM, qui authentifie les données : une
///   phrase erronée ou un fichier altéré sont détectés, et non déchiffrés en
///   silence vers des données fausses.
///
/// Le sel et les paramètres sont stockés en clair dans l'enveloppe : ils ne
/// sont pas secrets, et sans eux la sauvegarde serait irrécupérable.
class BackupCrypto {
  const BackupCrypto();

  /// Version du format, pour rester capable de relire d'anciennes sauvegardes.
  static const formatVersion = 1;

  /// Compromis usuel entre robustesse et temps de calcul sur un téléphone.
  static const iterations = 120000;

  static const _keyLengthBytes = 32;
  static const _saltLengthBytes = 16;
  static const _nonceLengthBytes = 12;

  static final _cipher = AesGcm.with256bits();

  /// Dérive la clé de chiffrement à partir de la phrase secrète et du sel.
  ///
  /// L'opération est volontairement lente : c'est ce qui rend une attaque par
  /// essais successifs coûteuse.
  Future<SecretKey> deriveKey(String passphrase, List<int> salt) {
    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: _keyLengthBytes * 8,
    );
    return kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  List<int> newSalt() => _randomBytes(_saltLengthBytes);

  /// Chiffre [plainText] et renvoie l'enveloppe JSON à écrire dans un fichier.
  Future<String> encrypt({required String plainText, required SecretKey key, required List<int> salt}) async {
    final nonce = _randomBytes(_nonceLengthBytes);
    final box = await _cipher.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );

    return jsonEncode({
      'version': formatVersion,
      'kdf': 'pbkdf2-hmac-sha256',
      'iterations': iterations,
      'cipher': 'aes-256-gcm',
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'data': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  /// Extrait le sel d'une enveloppe, nécessaire pour dériver la clé avant
  /// même de pouvoir tenter le déchiffrement.
  List<int> saltOf(String envelope) {
    final header = _parse(envelope);
    final salt = header['salt'];
    if (salt is! String) {
      throw const BackupDecryptException('Ce fichier n’est pas une sauvegarde Vaulti.');
    }
    return base64Decode(salt);
  }

  /// Déchiffre une enveloppe. Lève [BackupDecryptException] si la phrase est
  /// incorrecte ou si le fichier a été modifié.
  Future<String> decrypt({required String envelope, required SecretKey key}) async {
    final header = _parse(envelope);

    final version = header['version'];
    if (version is! int || version > formatVersion) {
      throw const BackupDecryptException(
        'Cette sauvegarde a été créée avec une version plus récente de Vaulti.',
      );
    }

    try {
      final box = SecretBox(
        base64Decode(header['data'] as String),
        nonce: base64Decode(header['nonce'] as String),
        mac: Mac(base64Decode(header['mac'] as String)),
      );
      final clear = await _cipher.decrypt(box, secretKey: key);
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      // AES-GCM ne distingue pas les deux cas : dans les deux, la clé issue de
      // la phrase ne correspond pas aux données.
      throw const BackupDecryptException(
        'Mot de passe incorrect, ou fichier de sauvegarde endommagé.',
      );
    } on FormatException {
      throw const BackupDecryptException('Ce fichier n’est pas une sauvegarde Vaulti.');
    } on TypeError {
      throw const BackupDecryptException('Ce fichier n’est pas une sauvegarde Vaulti.');
    }
  }

  Map<String, dynamic> _parse(String envelope) {
    try {
      final decoded = jsonDecode(envelope);
      if (decoded is! Map<String, dynamic>) {
        throw const BackupDecryptException('Ce fichier n’est pas une sauvegarde Vaulti.');
      }
      return decoded;
    } on FormatException {
      throw const BackupDecryptException('Ce fichier n’est pas une sauvegarde Vaulti.');
    }
  }

  /// Générateur du système, cryptographiquement sûr.
  ///
  /// Indispensable ici : en AES-GCM, un nonce prévisible ou réutilisé
  /// compromet le chiffrement. Un générateur « rapide » serait une faille.
  static final _random = Random.secure();

  static Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }
}
