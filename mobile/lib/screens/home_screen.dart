import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import 'bookings_tab.dart';
import 'messages_tab.dart';
import 'profile_tab.dart';
import 'search_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photoUrl = Api.currentUser?['photoUrl'] as String?;
    final initial = ((Api.currentUser?['name'] ?? '?') as String).isNotEmpty
        ? (Api.currentUser?['name'] ?? '?')[0]
        : '?';

    // Onglet Profil : affiche la photo de profil (ou l'initiale)
    Widget profileIcon(bool selected) {
      return Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 12,
          backgroundColor: gologuiTeal,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(initial,
                  style: const TextStyle(color: Colors.white, fontSize: 12))
              : null,
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [SearchTab(), BookingsTab(), MessagesTab(), ProfileTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        // Icônes façon Airbnb : contour quand inactif, plein quand actif
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explorer',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Réservations',
          ),
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: profileIcon(false),
            selectedIcon: profileIcon(true),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
