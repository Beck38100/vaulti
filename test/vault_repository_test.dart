import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaulti/dialogs.dart';
import 'package:vaulti/models.dart';
import 'package:vaulti/vault_marker.dart';
import 'package:vaulti/vault_repository.dart';

import 'helpers.dart';

/// Stockage dont toute lecture échoue, comme un magasin de clés en erreur.
class _FailingStorage extends Fake implements FlutterSecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<String?>.error(PlatformException(code: 'keystore'));
}

/// Repère dans un dossier temporaire : les tests ne touchent jamais au vrai
/// dossier de l'application.
VaultMarker tempMarker() {
  final dir = Directory.systemTemp.createTempSync('vaulti-repere-test');
  addTearDown(() => dir.deleteSync(recursive: true));
  return VaultMarker(() async => dir);
}

/// Place [raw] sous la clé du coffre, puis tente de le lire.
Future<VaultData> loadFrom(Map<String, String> stored) {
  FlutterSecureStorage.setMockInitialValues(stored);
  return VaultRepository(const FlutterSecureStorage(), tempMarker()).loadVault();
}

void main() {
  group('lecture du coffre', () {
    test('aucun coffre enregistré : coffre vide (premier lancement)', () async {
      final data = await loadFrom({});
      expect(data.entries, isEmpty);
      expect(data.folders, isEmpty);
    });

    test('un coffre valide se relit tel qu’il a été enregistré', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repository = VaultRepository(const FlutterSecureStorage(), tempMarker());
      await repository.saveVault(VaultData(
        folders: [VaultFolder(id: 'f1', title: 'Banque')],
        entries: [],
      ));

      final data = await repository.loadVault();

      expect(data.folders.single.title, 'Banque');
    });

    test('l’ancien format (liste de fiches) reste lisible', () async {
      final data = await loadFrom({
        'vault_passwords': '[{"id":"a","title":"Site","user":"moi","pass":"x"}]',
      });
      expect(data.entries.single.title, 'Site');
    });

    test('un contenu qui n’est pas du JSON est signalé, pas remplacé par un coffre vide', () async {
      await expectLater(loadFrom({'vault_data': '{ceci n’est pas du json'}), throwsA(isA<VaultUnreadableException>()));
    });

    test('un JSON de forme inattendue est signalé', () async {
      await expectLater(loadFrom({'vault_data': '"une simple chaîne"'}), throwsA(isA<VaultUnreadableException>()));
    });

    test('une fiche mal formée est signalée', () async {
      await expectLater(
        loadFrom({'vault_data': '{"folders":[],"entries":["pas une fiche"]}'}),
        throwsA(isA<VaultUnreadableException>()),
      );
    });

    test('une erreur de lecture du stockage est signalée', () async {
      await expectLater(
        VaultRepository(_FailingStorage(), tempMarker()).loadVault(),
        throwsA(isA<VaultUnreadableException>()),
      );
    });

    test('lire un coffre illisible ne modifie pas la donnée enregistrée', () async {
      const corrupted = '{ceci n’est pas du json';
      FlutterSecureStorage.setMockInitialValues({'vault_data': corrupted});
      final repository = VaultRepository(const FlutterSecureStorage(), tempMarker());

      await expectLater(repository.loadVault(), throwsA(isA<VaultUnreadableException>()));

      expect(await const FlutterSecureStorage().read(key: 'vault_data'), corrupted);
    });
  });

  group('clé de sauvegarde et itérations', () {
    test('une clé enregistrée sans valeur d’itérations (ancienne version) vaut 120 000', () async {
      FlutterSecureStorage.setMockInitialValues({'backup_key': 'AAEC', 'backup_salt': 'AwQF'});

      final stored = await VaultRepository(const FlutterSecureStorage(), tempMarker()).readBackupKey();

      expect(stored!.iterations, 120000);
    });

    test('la valeur enregistrée avec la clé se relit', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repository = VaultRepository(const FlutterSecureStorage(), tempMarker());

      await repository.saveBackupKey([1, 2, 3], [4, 5, 6], 300000);

      expect((await repository.readBackupKey())!.iterations, 300000);
    });

    test('une valeur enregistrée hors bornes est ignorée au profit de 120 000', () async {
      FlutterSecureStorage.setMockInitialValues({
        'backup_key': 'AAEC',
        'backup_salt': 'AwQF',
        'backup_iterations': '5',
      });

      final stored = await VaultRepository(const FlutterSecureStorage(), tempMarker()).readBackupKey();

      expect(stored!.iterations, 120000);
    });
  });

  group('fenêtre « coffre illisible »', () {
    Future<Future<VaultRecovery>> open(WidgetTester tester) async {
      late Future<VaultRecovery> result;
      await tester.pumpWidget(wrap(Builder(builder: (context) {
        return ElevatedButton(onPressed: () => result = askVaultRecovery(context), child: const Text('ouvrir'));
      })));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('annonce que rien n’a été effacé et propose les trois choix', (tester) async {
      await open(tester);

      expect(find.textContaining('n’écrit rien tant que tu n’as pas choisi'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.text('Importer une sauvegarde'), findsOneWidget);
      expect(find.text('Repartir d’un coffre vide'), findsOneWidget);
    });

    testWidgets('ne se ferme pas en touchant à côté', (tester) async {
      await open(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(find.text('Coffre illisible'), findsOneWidget);
    });

    for (final (label, expected) in [
      ('Réessayer', VaultRecovery.retry),
      ('Importer une sauvegarde', VaultRecovery.restoreBackup),
      ('Repartir d’un coffre vide', VaultRecovery.startEmpty),
    ]) {
      testWidgets('« $label » renvoie le bon choix', (tester) async {
        final result = await open(tester);

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(await result, expected);
      });
    }
  });
}
