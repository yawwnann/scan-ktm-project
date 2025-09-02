import 'package:flutter/material.dart';
import '../scan/scan_screen.dart';
import '../scan/ocr_screen.dart';
import '../student/student_list_screen.dart';
import '../scan/scan_history_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with AutomaticKeepAliveClientMixin, RouteAware {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const OCRScreen(key: ValueKey('ocr')),
    const StudentListScreen(key: ValueKey('student_list')),
    const ScanScreen(key: ValueKey('scan')), 
    const ScanHistoryScreen(key: ValueKey('scan_history')),
    const ProfileScreen(key: ValueKey('profile')),
  ];

  final RouteObserver<ModalRoute<void>> _routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Set barcode sebagai halaman default
    _currentIndex = 2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      _routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    super.didPushNext();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didPop() {
    super.didPop();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void didPush() {
    super.didPush();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // OCR
              _buildNavItem(
                icon: Icons.text_fields_outlined,
                activeIcon: Icons.text_fields,
                label: 'OCR',
                index: 0,
                colorScheme: colorScheme,
              ),
              // Mahasiswa
              _buildNavItem(
                icon: Icons.group_outlined,
                activeIcon: Icons.group,
                label: 'Mahasiswa',
                index: 1,
                colorScheme: colorScheme,
              ),
              // Barcode (Center - Floating)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => _onItemTapped(2),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              // Riwayat
              _buildNavItem(
                icon: Icons.access_time_outlined,
                activeIcon: Icons.access_time_filled,
                label: 'Riwayat',
                index: 3,
                colorScheme: colorScheme,
              ),
              // Profil
              _buildNavItem(
                icon: Icons.person_outlined,
                activeIcon: Icons.person,
                label: 'Profil',
                index: 4,
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required ColorScheme colorScheme,
  }) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 24,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }
}
