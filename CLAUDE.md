# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Vaulti is an offline Android password manager written in Flutter (package `fr.vaulti.app`). The UI, code comments and commit messages are in French; UI copy uses "tu". The only network access is Google Play Billing, used for the optional Premium purchase.

## Commands

```bash
flutter pub get
flutter analyze
flutter test                                        # the whole suite
flutter test test/backup_crypto_test.dart           # one file
flutter test test/widget_test.dart --plain-name "le bandeau"   # tests whose name contains this text
```

There are two Android flavors (`android/app/build.gradle.kts`), so **every** `flutter run` and `flutter build` needs `--flavor`:
- `production`: `fr.vaulti.app`, the only flavor that exists in Play Console.
- `dev`: `fr.vaulti.app.dev`, shown as "Vaulti Dev". It installs alongside the real app.

Device builds also need `--no-tree-shake-icons`, because icons are referenced through data structures that tree shaking can't follow:

```bash
flutter run --flavor dev -d <device-id>
flutter build apk --flavor dev --debug
flutter build appbundle --flavor production --release --no-tree-shake-icons   # upload to Play Console
```

- Release signing reads `android/key.properties` (gitignored). It points to `C:/Projet/Vaulti/vaulti-signing/`.
- Built artifacts are copied by hand to the sibling folder `../vaulti-releases/`.

**Do not run `dart format` on whole files.** The code is hand-formatted with lines around 120 characters. The default 80-column formatter rewrites unrelated code and produces huge diffs.

## Architecture

**State lives in one place.** `lib/screens/home_screen.dart` (`_HomeScreenState`) owns all mutable state: vault content, backup key, premium status, selected tab, open folder, lock timers. It also owns every side effect. On each build it creates a `VaultSession` (`lib/screens/vault_session.dart`): a read-only snapshot plus callbacks, passed to every tab. Tabs in `lib/screens/tabs/` are pure views and hold no business logic.

Adding a field to `VaultSession` means updating three places:
- `_buildSession()` in `home_screen.dart`
- the `VaultSession` constructor
- `fakeSession()` in `test/helpers.dart`

**Tabs.** The six tabs sit in an `IndexedStack`, and `onGoToTab` uses their indices:

| Index | Tab |
|---|---|
| 0 | Coffre (dashboard) |
| 1 | Mots de passe |
| 2 | Notes |
| 3 | Dossiers |
| 4 | Sécurité |
| 5 | Réglages |

- Only the Dossiers tab navigates the folder tree (`currentFolderId`).
- Coffre is a dashboard: score and category tiles.
- The Mots de passe and Notes tabs list the whole vault flat.
- The Android back gesture is intercepted with `PopScope` in `home_screen.dart`. It goes up one folder, then to Coffre, then exits the app.

**Pure logic vs widgets.** These files don't depend on any widget and are unit-tested in `test/`:
- `models.dart`
- `vault_repository.dart` (flutter_secure_storage)
- `vault_stats.dart`
- `password_strength.dart`
- `backup_crypto.dart`
- `premium.dart`

Widget tests use `wrap()` and `fakeSession()` from `test/helpers.dart`.

**Data format constraints.**
- `VaultEntry` JSON keys are legacy and must not change: `user`, `pass`, `note`.
- A note stores its body in the `identifier` field (JSON key `user`), and `comment` is under `note`.
- `VaultData.fromDecoded` also accepts the old format, where the vault was a bare list.

**Backups** (`backup_crypto.dart` and `backup_service.dart`):
- The file is a JSON envelope `{version, kdf, iterations, salt, nonce, data, mac}`, encrypted with PBKDF2-HMAC-SHA256 (120 000 iterations) and AES-256-GCM.
- Keep `formatVersion` backward compatible.
- The file name `vaulti-sauvegarde.vaulti` is hard-coded in `android/app/src/main/res/xml/backup_rules.xml` and `data_extraction_rules.xml`. It must stay in sync with `BackupService.fileName`.
- Importing a backup **replaces** the whole vault and also adopts that file's passphrase as the backup passphrase.
- Changing the passphrase requires re-entering the current one first (`_confirmCurrentPassphrase`).

**Premium.**
- `PremiumLimits` (`premium.dart`) holds the free-tier caps.
- `PurchaseService` (`purchase_service.dart`) wraps `in_app_purchase`. Its product ID `premiumProductId = 'vaulti_premium_lifetime'` must match the managed product in Play Console exactly.
- Validation is client-side only (`VaultRepository.saveIsPremium`); there is no server.
- Billing only works on the `production` flavor installed **from a Play testing track**. It never works with `flutter run` or a sideloaded APK.

**Native Android.** `android/app/src/main/kotlin/fr/vaulti/app/MainActivity.kt` exposes two method channels:
- `vaulti/screen_security`: turns FLAG_SECURE on or off. It is on from `onCreate`.
- `vaulti/secure_clipboard`: copies with `EXTRA_IS_SENSITIVE` and clears the clipboard only if it still holds Vaulti's own clip (checked by label, never by reading the content).

## Pitfalls

- **Form dialogs** must close with `closeDialog()` and release their controllers with `disposeAfterFrame()` (`lib/dialogs/form_shell.dart`). Otherwise Flutter throws the `_dependents.isEmpty` assertion.
- **FLAG_SECURE blocks `adb screencap`**, so on-device UI can't be checked by screenshot. Check UI changes on the web build instead (`flutter run -d chrome` or `-d web-server`). On web, biometric auth is auto-granted, while `path_provider` (backups) and billing are unavailable.
- **Privacy policy.** `docs/vaulti/politique-de-confidentialite.md` and `docs/vaulti/index.html` are two copies of the same policy, published via GitHub Pages at https://beck38100.github.io/vaulti/vaulti/. Keep both in sync and bump the "Dernière mise à jour" date on every change.
- **Reduced motion.** Any new animation must honor the Android "remove animations" setting through `Motion.reduced(context)` / `Motion.of(context, duration)` (`lib/widgets/animations.dart`); the existing ones all do, and `test/motion_test.dart` covers the shared widgets.
- **Dark launch.** The launch/normal themes (`values/styles.xml`, `values-v31/styles.xml`) are deliberately dark for every phone mode, with `launch_background` = `AppColors.background`. There is no `values-night`: keep it that way, or a light-mode phone flashes white at startup.
- **Themed icon (Android 13+).** `mipmap-anydpi-v26/ic_launcher.xml` has a hand-added `<monochrome>` layer pointing at `drawable-nodpi/ic_launcher_monochrome.png` (a white silhouette derived from the foreground icon). Re-running `flutter_launcher_icons` overwrites that XML and silently drops the layer: re-add it.
- **`ios/`** is untouched scaffolding. The app is not built for iOS, but `Info.plist` already contains a Face ID usage string.
