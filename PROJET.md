# PROJET.md — Vaulti

Dernière mise à jour : 2026-10-08

## Objectif

Vaulti est un gestionnaire de mots de passe Android hors ligne : aucun compte, aucun serveur, tout reste sur le téléphone (README, CLAUDE.md). Seul accès réseau : l'achat Premium optionnel via Google Play Facturation.

Modèle économique : version gratuite limitée (3 dossiers, 10 mots de passe, 8 notes) et achat unique Premium à vie, sans abonnement (`lib/premium.dart`, `test/premium_test.dart`). Prix : 4,99 € (Play Console).

Objectif en cours : obtenir l'accès à la production sur Google Play (test fermé de 14 jours consécutifs avec au moins 12 testeurs, puis formulaire d'accès production). Le test est en cours, pas encore terminé ; date de début [à confirmer].

## Technologie

- Flutter / Dart (`sdk: ^3.13.2`), application Android uniquement (`ios/` est un gabarit inutilisé).
- Package `fr.vaulti.app`, version actuelle `1.0.4+5` (`pubspec.yaml`).
- Deux flavors Android : `production` (`fr.vaulti.app`) et `dev` (`fr.vaulti.app.dev`, « Vaulti Dev », installable en parallèle).
- Stockage : `flutter_secure_storage`. Déverrouillage : `local_auth`. Sauvegarde chiffrée : PBKDF2-HMAC-SHA256 (120 000 itérations) + AES-256-GCM (`cryptography`).
- Code natif Android : `MainActivity.kt` (FLAG_SECURE, presse-papiers sensible).
- Interface, commentaires et messages de commit en français ; l'interface tutoie l'utilisateur.
- Dépôt : https://github.com/Beck38100/vaulti (branche principale `main`).

## Règles et consignes

Tirées de CLAUDE.md, README.md et du dépôt :

- Toute commande `flutter run` / `flutter build` doit préciser `--flavor production` ou `--flavor dev`.
- Tout build destiné à un appareil utilise `--no-tree-shake-icons`.
- **Ne jamais lancer `dart format` sur des fichiers entiers** : le code est formaté à la main (~120 colonnes).
- Ajouter un champ à `VaultSession` = modifier 3 endroits : `_buildSession()` dans `home_screen.dart`, le constructeur, `fakeSession()` dans `test/helpers.dart`.
- Les clés JSON de `VaultEntry` (`user`, `pass`, `note`) sont historiques et ne doivent pas changer ; garder `formatVersion` de la sauvegarde rétrocompatible.
- Le nom `vaulti-sauvegarde.vaulti` est écrit en dur dans `backup_rules.xml` et `data_extraction_rules.xml` : à garder synchronisé avec `BackupService.fileName`.
- Les fenêtres de formulaire se ferment avec `closeDialog()` et libèrent leurs contrôleurs avec `disposeAfterFrame()`.
- Toute nouvelle animation respecte `Motion.reduced(context)` / `Motion.of(context, durée)`.
- Thème de lancement volontairement sombre : ne pas recréer `values-night`.
- Régénérer l'icône avec `flutter_launcher_icons` supprime la couche `<monochrome>` : la remettre à la main.
- Politique de confidentialité : `docs/vaulti/politique-de-confidentialite.md` et `docs/vaulti/index.html` sont deux copies à garder identiques, avec la date « Dernière mise à jour » à changer à chaque modification.
- `android/key.properties`, les `*.p12` et `*.jks` ne sont jamais versionnés. Perdre la clé de signature interdit toute mise à jour sur le Play Store : elle doit être sauvegardée hors du poste (README).
- La facturation ne se teste pas avec `flutter run` ni un APK installé à la main : il faut une version `production` installée depuis une piste de test Play.
- FLAG_SECURE bloque `adb screencap` : vérifier l'interface avec le build web.
- Ne rien construire du backlog sans accord explicite de l'utilisateur ; confirmer avant toute action visible par d'autres (par ex. un push git).

## Décisions prises

- Tout reste local, aucun serveur ; validation de l'achat côté appareil seulement (README).
- L'onglet Coffre est un tableau de bord ; seul l'onglet Dossiers navigue dans l'arborescence (README, CLAUDE.md).
- Achat Premium unique et non consommable, identifiant `vaulti_premium_lifetime` (identique dans Play Console).
- Limites gratuites resserrées en 1.0.4 : 3 dossiers, 10 mots de passe, 8 notes (commit b704a94).
- Sauvegarde chiffrée reprise par la sauvegarde automatique d'Android.
- Décision prise : l'appli est en test chez Testers Community. Test fermé : piste « Alpha » ; testeurs recrutés via le service payant Testers Community (formule Starter, 15 testeurs) ; la liste de la famille a été abandonnée volontairement ; publication gérée activée dans Play Console.
- Trois mises à jour (1.0.2, 1.0.3, 1.0.4) envoyées une à une pendant le test, parce que Testers Community exige au moins 3 nouvelles versions visibles.

## Outils et bibliothèques utilisés

Dépendances (`pubspec.yaml`) :
- `flutter_secure_storage` ^11.0.0 — coffre chiffré par le magasin de clés du téléphone
- `local_auth` ^3.0.2 — empreinte, visage ou code de l'appareil
- `cryptography` ^2.7.0 — dérivation de clé et chiffrement de la sauvegarde
- `path_provider` ^2.1.5 — emplacement du fichier de sauvegarde
- `file_picker` ^12.2.0 — export et import manuels de la sauvegarde
- `url_launcher` ^6.3.1 — ouvre le formulaire de retour dans le navigateur
- `in_app_purchase` ^3.3.0 — achat Premium via Google Play Facturation

Développement : `flutter_lints` ^6.0.0, `flutter_launcher_icons` ^0.14.4.

Services externes : Play Console, GitHub Pages (politique de confidentialité), Google Forms (retour utilisateur), Testers Community.

Catalogue d'outils personnel (`catalogue-outils`) : [à confirmer : non consulté pour ce projet, déjà construit avant].

## État

**Fait**
- Application 1.0.0 : coffre hors ligne, sauvegarde chiffrée, fiche Play Store, politique de confidentialité en ligne.
- 1.0.1 : verrouillage sans code d'appareil mieux guidé, annulation de l'empreinte non traitée comme une panne.
- Achat Premium réel branché (Google Play Facturation).
- 1.0.2 : jauge de solidité de la phrase de sauvegarde, texte 12 px, icône thématique Android 13+.
- 1.0.3 : réduction des animations respectée, retours haptiques, lancement sombre sans flash clair.
- 1.0.4 : version gratuite resserrée à 10 mots de passe et 8 notes.
- Tout est poussé sur GitHub ; les fichiers de version sont dans `../vaulti-releases/`.

**En cours**
- 1.0.2 envoyée pour examen dans Play Console (au 2026-10-07) ; il restera à cliquer « Publier » après approbation.
- Test fermé de 14 jours avec Testers Community.

**À faire**
- Envoyer 1.0.3 (environ jours 7-8) puis 1.0.4 (environ jours 11-12), chacune avec ses notes de version.
- Mettre à jour la description du Play Store (« jusqu'à 3 dossiers, 10 mots de passe et 8 notes ») à la sortie de la 1.0.4.
- Vérifier les installations et le nombre de testeurs inscrits (au moins 12), puis remplir le formulaire d'accès production.
- Vérifier sur un vrai téléphone : haptique, lancement sans flash blanc en mode clair, icône thématique.
- Vérifier le remboursement de l'achat de test.
- Backlog gardé en attente : écran vide au démarrage, PBKDF2 à 600 000 itérations, test grande police, e-mail professionnel (fiche Play, profil marchand, politique de confidentialité), statut juridique d'éditeur.
- Idées v2 : lier l'empreinte à la clé du coffre (Keystore), import depuis d'autres gestionnaires.

## Liens

- Dépôt : https://github.com/Beck38100/vaulti
- Politique de confidentialité : https://beck38100.github.io/vaulti/vaulti/
- Guide technique : `CLAUDE.md` ; documentation : `README.md`
- Dossiers voisins hors dépôt : `../vaulti-releases/` (fichiers de version), `../vaulti-signing/` (clé de signature, ne jamais versionner)
- Play Console : [à confirmer : lien direct vers l'application, à me donner]
- Testers Community : https://www.testerscommunity.com/
