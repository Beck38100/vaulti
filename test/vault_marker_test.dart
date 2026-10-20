import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/models.dart';
import 'package:vaulti/vault_marker.dart';
import 'package:vaulti/vault_repository.dart';

Directory tempDir() {
  final dir = Directory.systemTemp.createTempSync('vaulti-repere-test');
  addTearDown(() => dir.deleteSync(recursive: true));
  return dir;
}

VaultRepository repositoryIn(Directory dir) =>
    VaultRepository(const FlutterSecureStorage(), VaultMarker(() async => dir));

VaultData oneFolder() => VaultData(folders: [VaultFolder(id: 'f1', title: 'Banque')], entries: []);

void main() {
  group('fichier repère', () {
    test('premier lancement (ni coffre ni repère) : coffre vide, sans alerte', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final data = await repositoryIn(tempDir()).loadVault();
      expect(data.entries, isEmpty);
    });

    test('l’enregistrement du coffre pose le repère', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final dir = tempDir();
      await repositoryIn(dir).saveVault(oneFolder());
      expect(File('${dir.path}/${VaultMarker.fileName}').existsSync(), isTrue);
    });

    test('le repère ne contient aucune donnée du coffre', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final dir = tempDir();
      await repositoryIn(dir).saveVault(oneFolder());
      expect(File('${dir.path}/${VaultMarker.fileName}').readAsStringSync(), '1');
    });

    test('repère présent mais coffre disparu du stockage : signalé, pas un coffre vide', () async {
      final dir = tempDir();
      FlutterSecureStorage.setMockInitialValues({});
      await repositoryIn(dir).saveVault(oneFolder());

      // Le plugin a effacé ses données : le stockage est vide, le repère reste.
      FlutterSecureStorage.setMockInitialValues({});

      await expectLater(repositoryIn(dir).loadVault(), throwsA(isA<VaultUnreadableException>()));
    });

    test('repère et coffre présents : lecture normale', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final dir = tempDir();
      final repository = repositoryIn(dir);
      await repository.saveVault(oneFolder());

      final data = await repository.loadVault();

      expect(data.folders.single.title, 'Banque');
    });

    test('un coffre vidé par l’utilisateur (sans aucune fiche) n’est pas une alerte', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final dir = tempDir();
      final repository = repositoryIn(dir);
      await repository.saveVault(VaultData.empty());

      final data = await repository.loadVault();

      expect(data.entries, isEmpty);
    });

    test('après « repartir d’un coffre vide », le coffre se relit normalement', () async {
      final dir = tempDir();
      FlutterSecureStorage.setMockInitialValues({});
      await repositoryIn(dir).saveVault(oneFolder());
      FlutterSecureStorage.setMockInitialValues({}); // coffre effacé par le plugin

      await repositoryIn(dir).saveVault(VaultData.empty()); // choix de l'utilisateur

      expect((await repositoryIn(dir).loadVault()).entries, isEmpty);
    });

    test('lire un coffre existant pose le repère (utilisateurs d’avant la protection)', () async {
      // Coffre déjà enregistré par une version sans repère : rien dans le dossier.
      FlutterSecureStorage.setMockInitialValues({'vault_data': '{"folders":[],"entries":[]}'});
      final dir = tempDir();
      final marker = File('${dir.path}/${VaultMarker.fileName}');
      expect(marker.existsSync(), isFalse);

      await repositoryIn(dir).loadVault();

      expect(marker.existsSync(), isTrue);
    });

    test('un coffre d’avant la protection, lu une fois, est ensuite protégé contre sa disparition', () async {
      final dir = tempDir();
      FlutterSecureStorage.setMockInitialValues({'vault_data': '{"folders":[],"entries":[]}'});
      await repositoryIn(dir).loadVault();

      FlutterSecureStorage.setMockInitialValues({}); // le plugin efface le coffre

      await expectLater(repositoryIn(dir).loadVault(), throwsA(isA<VaultUnreadableException>()));
    });

    test('un coffre à l’ancien format (liste de fiches) pose aussi le repère', () async {
      FlutterSecureStorage.setMockInitialValues({'vault_passwords': '[]'});
      final dir = tempDir();

      await repositoryIn(dir).loadVault();

      expect(File('${dir.path}/${VaultMarker.fileName}').existsSync(), isTrue);
    });

    test('un coffre illisible ne pose pas de repère', () async {
      FlutterSecureStorage.setMockInitialValues({'vault_data': '{ceci n’est pas du json'});
      final dir = tempDir();

      await expectLater(repositoryIn(dir).loadVault(), throwsA(isA<VaultUnreadableException>()));

      expect(File('${dir.path}/${VaultMarker.fileName}').existsSync(), isFalse);
    });

    test('un dossier de repère inutilisable n’empêche ni d’enregistrer ni de lire', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final dir = tempDir();
      final broken = VaultRepository(
        const FlutterSecureStorage(),
        VaultMarker(() async => throw const FileSystemException('indisponible')),
      );

      await broken.saveVault(oneFolder());
      final data = await broken.loadVault();

      expect(data.folders.single.title, 'Banque');
      expect(dir.listSync(), isEmpty);
    });
  });

  group('règles de sauvegarde Android', () {
    // Garde-fou : un repère sauvegardé puis restauré sur un autre téléphone, où
    // le coffre n'existe pas, provoquerait une fausse alerte.
    for (final rules in [
      ('backup_rules.xml', 1),
      ('data_extraction_rules.xml', 2),
    ]) {
      test('${rules.$1} n’emporte que la sauvegarde chiffrée, jamais le repère', () {
        final xml = File('android/app/src/main/res/xml/${rules.$1}').readAsStringSync();

        expect(xml.contains(VaultMarker.fileName), isFalse);
        expect(RegExp(r'<include ').allMatches(xml).length, rules.$2);
        expect(
          RegExp(r'<include domain="root" path="app_flutter/vaulti-sauvegarde\.vaulti"/>').allMatches(xml).length,
          rules.$2,
        );
      });
    }
  });
}
