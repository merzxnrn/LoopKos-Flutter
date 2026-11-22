import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../screens/bundle_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/sell_room_screen.dart';
import '../screens/transactions_screen.dart';
import 'app_background.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  final List<Widget>? pages;

  const MainShell({
    super.key,
    this.initialIndex = 0,
    this.pages,
  });

  static final List<MainShellState> _mountedShells = [];

  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<MainShellState>();
    if (state != null && state.mounted) {
      state.setTab(index);
      return;
    }

    final currentNav = Navigator.maybeOf(context);
    MainShellState? rootShell;
    for (final shell in _mountedShells) {
      if (shell.mounted && Navigator.maybeOf(shell.context) == currentNav) {
        rootShell = shell;
        break;
      }
    }
    if (rootShell != null) {
      final targetRoute = ModalRoute.of(rootShell.context);
      rootShell.setTab(index);
      if (targetRoute != null) {
        Navigator.of(context).popUntil(
          (route) => route == targetRoute || route.isFirst,
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }

    const routes = ['/home', '/bundle', '/sell', '/transactions', '/profile'];
    final target = routes[index.clamp(0, routes.length - 1)];
    Navigator.of(context).pushNamedAndRemoveUntil(target, (r) => false);
  }

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _currentIndex;

  List<Widget> get _pages =>
      widget.pages ??
      const [
        HomeScreen(),
        BundleScreen(),
        SellRoomScreen(),
        TransactionsScreen(),
        ProfileScreen(),
      ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _pages.length - 1);
    MainShell._mountedShells.add(this);
  }

  @override
  void dispose() {
    MainShell._mountedShells.remove(this);
    super.dispose();
  }

  void setTab(int index) {
    final clamped = index.clamp(0, _pages.length - 1);
    if (clamped == _currentIndex) return;
    setState(() => _currentIndex = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderGlass)),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: setTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.layers_outlined),
                selectedIcon: Icon(Icons.layers_rounded),
                label: 'Bundle',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_box_outlined),
                selectedIcon: Icon(Icons.add_box_rounded),
                label: 'Jual',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Transaksi',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
