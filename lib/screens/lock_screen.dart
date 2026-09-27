import 'package:flutter/material.dart';

import '../auth_service.dart';
import '../theme.dart';
import 'home_screen.dart';

/// Écran d'accueil verrouillé : rien n'est accessible avant authentification.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = AuthService();
  bool _isAuthenticating = false;
  AuthResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _lastResult = null;
    });

    final result = await _auth.authenticate('Déverrouille ton coffre Vaulti');
    if (!mounted) return;

    if (result.granted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    setState(() {
      _isAuthenticating = false;
      _lastResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final message = _lastResult?.message;
    final needsDeviceLock = _lastResult?.outcome == AuthOutcome.noDeviceLock;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.shield_outlined, size: 80, color: AppColors.signature),
            const SizedBox(height: 20),
            const Text('Vaulti', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Ton coffre est verrouillé',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            const SizedBox(height: 30),
            if (message != null) ...[
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.warningText, fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
            // Sans verrouillage, réessayer ne mène nulle part : l'action utile
            // passe en premier, le déverrouillage reste disponible pour le retour.
            if (needsDeviceLock) ...[
              FilledButton.icon(
                onPressed: _auth.openDeviceLockSettings,
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Ouvrir les réglages de sécurité'),
              ),
              const SizedBox(height: 10),
            ],
            ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _unlock,
              icon: const Icon(Icons.fingerprint),
              label: Text(needsDeviceLock ? 'C’est fait, réessayer' : 'Déverrouiller'),
            ),
          ]),
        ),
      ),
    );
  }
}
