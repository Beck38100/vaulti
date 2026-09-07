# Politique de confidentialité — Vaulti

**Dernière mise à jour : 7 septembre 2026**

Vaulti est un gestionnaire de mots de passe qui fonctionne entièrement sur votre
téléphone. Cette politique explique quelles données l'application manipule, où
elles sont stockées, et qui peut y accéder.

En résumé : **Vaulti ne collecte aucune donnée personnelle, ne contient aucune
publicité, aucun outil de mesure d'audience. Le seul échange réseau de
l'application sert à traiter l'achat Premium optionnel, via Google Play.**

---

## 1. Qui est responsable de l'application

Vaulti est publiée par un développeur indépendant.
Contact : `qualf404@gmail.com`

## 2. Quelles données l'application manipule

Vaulti enregistre uniquement ce que vous y saisissez vous-même :

- les mots de passe, identifiants, notes et commentaires que vous créez ;
- les dossiers que vous créez pour les organiser ;
- votre prénom, si vous choisissez de le renseigner, uniquement pour afficher un
  message d'accueil ;
- vos préférences (délai de verrouillage automatique, blocage des captures d'écran).

L'application ne demande ni votre adresse e-mail, ni votre numéro de téléphone,
ni aucun compte utilisateur. Il n'y a pas d'inscription.

## 3. Où ces données sont stockées

Toutes ces données restent **sur votre appareil**, dans le stockage sécurisé
d'Android. Elles y sont chiffrées par une clé détenue par le magasin de clés du
système (Android Keystore), qui ne quitte jamais le téléphone, et ne sont
accessibles qu'à Vaulti.

**Vaulti n'envoie aucune donnée personnelle sur Internet.** Le seul accès
réseau de l'application sert à traiter l'achat Premium optionnel via Google
Play Facturation (voir section 7) — aucune autre fonction n'y a recours.

## 4. La sauvegarde chiffrée

Vaulti propose une sauvegarde destinée à retrouver votre coffre si vous perdez
ou changez de téléphone. Son fonctionnement :

1. Vous choisissez un **mot de passe de sauvegarde**, connu de vous seul.
2. Une clé de chiffrement en est dérivée (PBKDF2-HMAC-SHA256, 120 000
   itérations), puis le contenu de votre coffre est chiffré avec cette clé
   (AES-256-GCM).
3. Le fichier obtenu est **illisible sans votre mot de passe de sauvegarde**.

Ce fichier chiffré est repris par la **sauvegarde automatique d'Android**, une
fonction du système d'exploitation qui le dépose sur votre propre compte Google
(Google Drive), comme pour les autres applications de votre téléphone. Ce
transfert est réalisé par Android, pas par Vaulti.

Concrètement :

- votre mot de passe de sauvegarde **n'est jamais enregistré ni transmis** :
  seule la clé qui en dérive est conservée, dans le stockage sécurisé du
  téléphone ;
- ni le développeur de Vaulti, ni Google, ni personne d'autre ne peut lire le
  contenu de cette sauvegarde sans ce mot de passe ;
- **si vous oubliez ce mot de passe, la sauvegarde est définitivement
  irrécupérable.** C'est la contrepartie de ce niveau de protection.

Vous pouvez désactiver cette sauvegarde à tout moment dans les réglages Android
de votre téléphone (Système → Sauvegarde).

Vous pouvez également exporter vous-même une copie chiffrée de votre coffre, à
l'endroit de votre choix. Ce que vous faites ensuite de ce fichier relève de
votre responsabilité.

## 5. Empreinte digitale et déverrouillage

Vaulti utilise le déverrouillage biométrique d'Android (empreinte, visage ou
code de l'appareil). Vos données biométriques sont gérées par le système
d'exploitation et **ne sont jamais transmises à l'application** : Vaulti reçoit
uniquement une réponse « authentification réussie » ou « échouée ».

## 6. Partage avec des tiers

Vaulti ne transmet vos données à aucun tiers, ne les vend pas, ne les utilise à
aucune fin publicitaire ou statistique. L'application n'intègre aucun kit de
développement tiers de mesure d'audience, de publicité ou de suivi.

Le bouton « Donner mon avis » des réglages est le seul lien vers l'extérieur :
il ouvre, dans votre navigateur, un formulaire Google Forms externe où vous
pouvez laisser un retour, entièrement facultatif. Vaulti n'y transmet rien
automatiquement et ne reçoit aucune réponse : ce que vous choisissez d'y écrire
relève de la politique de confidentialité de Google.

## 7. Achat intégré (Vaulti Premium)

Vaulti propose un achat unique, optionnel, pour lever les limites de la version
gratuite (nombre de dossiers, mots de passe et notes). Cet achat est entièrement
géré par **Google Play Facturation** (Google Play Billing) : Vaulti n'a accès à
aucune information de paiement (numéro de carte, coordonnées bancaires...), ne
les stocke pas et ne peut pas y accéder.

Google traite ces données selon sa propre politique de confidentialité :
https://policies.google.com/privacy

Vaulti conserve uniquement, sur votre appareil, une information technique
indiquant si l'achat a été effectué (« Premium » ou non) — aucune autre donnée
n'est associée à cet achat côté application.

Cette fonctionnalité nécessite un accès réseau, uniquement au moment de l'achat
ou de sa vérification.

## 8. Presse-papiers

Lorsque vous copiez un mot de passe, il est placé dans le presse-papiers
d'Android pour que vous puissiez le coller ailleurs. Vaulti le marque comme
contenu sensible : à partir d'Android 13, le système masque son aperçu à l'écran
et les claviers ne le gardent pas dans leur historique.

Vaulti l'efface automatiquement au bout de 45 secondes, et uniquement si le
presse-papiers contient encore sa propre copie : ce que vous auriez copié
entre-temps n'est jamais effacé, et l'application ne relit pas le contenu placé
là par d'autres. Selon la version d'Android, d'autres applications peuvent
techniquement lire le presse-papiers pendant ce court intervalle : c'est un
comportement du système, indépendant de Vaulti.

## 9. Suppression de vos données

- **Une entrée** : supprimez-la depuis l'application.
- **Tout le coffre** : désinstallez Vaulti, ou effacez les données de
  l'application dans les réglages Android. Tout est alors définitivement perdu.
- **La sauvegarde en ligne** : supprimez-la depuis les réglages de sauvegarde de
  votre compte Google (Google One → Sauvegardes → Données d'application).

Aucune donnée n'étant détenue par le développeur, il n'y a pas de demande de
suppression à lui adresser.

## 10. Enfants

Vaulti ne s'adresse pas spécifiquement aux enfants et ne collecte
volontairement aucune donnée les concernant.

## 11. Vos droits (RGPD)

Le développeur de Vaulti ne collecte, ne détient et ne traite aucune donnée
personnelle vous concernant. Vous restez seul détenteur de vos données, sur
votre appareil : vous pouvez y accéder, les modifier, les exporter et les
supprimer directement depuis l'application, à tout moment et sans intermédiaire.

## 12. Modifications de cette politique

Toute évolution de cette politique sera publiée sur cette page, avec une
nouvelle date de mise à jour. Si un changement affectait la façon dont vos
données sont traitées, il serait également annoncé dans les notes de version de
l'application.

## 13. Contact

Pour toute question relative à cette politique :
`qualf404@gmail.com`
