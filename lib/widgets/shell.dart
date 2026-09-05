import 'package:flutter/material.dart';

import '../theme.dart';

/// Bandeau supérieur permanent : identité de l'application et verrouillage rapide.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.onLock});

  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 4),
      child: Row(children: [
        const Icon(Icons.shield_outlined, color: AppColors.headerIcon, size: 28),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Mon Vaulti', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ),
        IconButton(
          tooltip: 'Verrouiller le coffre',
          icon: const Icon(Icons.lock_outline),
          onPressed: onLock,
        ),
      ]),
    );
  }
}

/// Une destination de la barre de navigation.
class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final Color color;
  final String label;
}

/// Barre de navigation intégrée au bas de la carte principale.
///
/// Les icônes inactives restent en gris neutre : seul l'onglet actif prend la
/// couleur de sa rubrique, ce qui le désigne sans surcharger la barre.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  static const destinations = [
    _NavDestination(icon: Icons.lock_outline, activeIcon: Icons.lock, color: AppColors.signature, label: 'Coffre'),
    _NavDestination(icon: Icons.key_outlined, activeIcon: Icons.key, color: AppColors.password, label: 'Mots de passe'),
    _NavDestination(icon: Icons.notes_outlined, activeIcon: Icons.notes, color: AppColors.note, label: 'Notes'),
    _NavDestination(icon: Icons.folder_outlined, activeIcon: Icons.folder, color: AppColors.folder, label: 'Dossiers'),
    _NavDestination(icon: Icons.shield_outlined, activeIcon: Icons.shield, color: AppColors.security, label: 'Sécurité'),
    _NavDestination(icon: Icons.settings_outlined, activeIcon: Icons.settings, color: Colors.white54, label: 'Réglages'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Stack(alignment: Alignment.center, children: [
        // Les destinations sont réparties de part et d'autre d'un espace central
        // réservé au bouton d'ajout, pour qu'il ne recouvre aucune icône.
        Row(children: [
          Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _items(0, 3))),
          const SizedBox(width: 68),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _items(3, destinations.length)),
          ),
        ]),
        Positioned(top: 4, child: _AddButton(onTap: onAdd)),
      ]),
    );
  }

  List<Widget> _items(int start, int end) {
    return List.generate(end - start, (offset) {
      final index = start + offset;
      return _NavItem(
        destination: destinations[index],
        selected: index == selectedIndex,
        onTap: () => onSelect(index),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap});

  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: destination.label,
      onPressed: onTap,
      icon: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: selected ? 1.15 : 1,
        child: Icon(
          selected ? destination.activeIcon : destination.icon,
          color: selected ? destination.color : Colors.white38,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.addButton,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(13),
          child: Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
