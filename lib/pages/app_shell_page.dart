import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lend_ledger/state/app_state.dart';
import 'package:provider/provider.dart';

import 'customers_page.dart';
import 'dashboard_page.dart';
import 'settings_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  late int _selectedNavIndex;

  final List<Widget> _tabs = const [
    DashboardPage(),
    CustomersPage(),
    DashboardReportsTab(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedNavIndex, children: _tabs),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.68),
                    const Color(0xFFF1DFDB).withValues(alpha: 0.64),
                  ],
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.72),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: "Home",
                  ),
                  _navItem(
                    index: 1,
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: "Customers",
                  ),
                  _navItem(
                    index: 2,
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart,
                    label: "Reports",
                  ),
                  _navItem(
                    index: 3,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: "Profile",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _selectedNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedNavIndex = index);
        if (index == 3) {
          context.read<AppState>().loadCurrentUserProfile(force: true);
        }
      },
      borderRadius: BorderRadius.circular(26),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: isActive
            ? Container(
                key: ValueKey('active_$index'),
                height: 46,
                width: 100,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A00),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(activeIcon, size: 20, color: Colors.white),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                key: ValueKey('inactive_$index'),
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFDADADA), width: 1),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF737373)),
              ),
      ),
    );
  }
}

