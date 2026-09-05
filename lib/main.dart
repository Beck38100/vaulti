import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VaultiApp());
}

class VaultiApp extends StatelessWidget {
  const VaultiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaulti',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Le Web sert d'aperçu de développement : il n'y a pas de biométrie,
      // on ouvre donc directement le coffre.
      home: kIsWeb ? const HomeScreen() : const LockScreen(),
    );
  }
}
