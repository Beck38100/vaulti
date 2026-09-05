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
  String? _error;

  @override
  void initState() {
    super.initState();
    _unlock();
  }

  Future<void> _unlock() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _error = null;
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
      _error = result.error == null
          ? 'Authentification refusée. Réessaie pour ouvrir ton coffre.'
          : 'Authentification indisponible sur cet appareil.';
    });
  }

  @override
  Widget build(BuildContext context) {
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
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.warningText, fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _unlock,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Déverrouiller'),
            ),
          ]),
        ),
      ),
    );
  }
}
