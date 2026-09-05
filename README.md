# Vaulti

Gestionnaire de mots de passe Android, hors ligne. Aucun compte, aucun serveur,
aucune permission réseau : tout reste sur le téléphone.

## Ce que fait l'application

- Coffre de mots de passe et de notes, rangés en dossiers.
- Ouverture par empreinte, visage ou code de l'appareil ; verrouillage
  automatique en arrière-plan.
- Indicateur de solidité des mots de passe, avec repérage des mots de passe
  faibles ou réutilisés.
- Sauvegarde chiffrée (PBKDF2-HMAC-SHA256 + AES-256-GCM) reprise par la
  sauvegarde automatique d'Android, et export/import manuel.

## Organisation du code

```
lib/
  main.dart                 point d'entrée
  theme.dart                palette, champs de saisie, formes communes
  models.dart               VaultEntry, VaultFolder, VaultData (+ JSON)
  vault_repository.dart     lecture/écriture dans le stockage sécurisé
  vault_stats.dart          score de sécurité, mots de passe à corriger
  password_strength.dart    calcul de solidité (source unique)
  auth_service.dart         biométrie
  screen_security.dart      blocage des captures d'écran (FLAG_SECURE)
  secure_clipboard.dart     copie marquée sensible, effacement du presse-papiers
  backup_crypto.dart        chiffrement de la sauvegarde
  backup_service.dart       fichier de sauvegarde et restauration
  dialogs.dart              regroupe lib/dialogs/ (voir l'en-tête du fichier)
  screens/                  écrans et onglets
  widgets/                  composants réutilisables
```

Le stockage et le chiffrement ne dépendent d'aucun widget : ils se testent
seuls, et c'est ce que fait `test/`.

## Développer

```bash
flutter pub get
flutter test          # 39 tests
flutter analyze
flutter run
```

Les icônes sont référencées via des structures de données, ce que l'élagage des
polices d'icônes ne sait pas suivre. Toute compilation destinée à un appareil
doit donc passer `--no-tree-shake-icons` :

```bash
flutter build apk --release --no-tree-shake-icons
flutter build appbundle --release --no-tree-shake-icons
```

Régénérer l'icône de l'application après avoir changé `assets/icon/vaulti.png` :

```bash
dart run flutter_launcher_icons
```

## Signature

La compilation en mode release lit `android/key.properties`, qui n'est pas dans
le dépôt et qui pointe vers le magasin de clés. **Perdre cette clé ou son mot de
passe interdit définitivement toute mise à jour de l'application sur le Play
Store** : elle doit être sauvegardée hors de ce poste.

## Sauvegarde automatique

`android/app/src/main/res/xml/backup_rules.xml` et `data_extraction_rules.xml`
n'incluent qu'un seul fichier : la sauvegarde chiffrée. Son chemin y est écrit
en dur (`app_flutter/vaulti-sauvegarde.vaulti`) et doit rester synchronisé avec
`BackupService.fileName`.

## Politique de confidentialité

`docs/vaulti/` contient la page publiée pour le Play Store, un dossier par
application.
