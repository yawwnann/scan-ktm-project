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
    const ScanScreen(key: ValueKey('scan')),
    const OCRScreen(key: ValueKey('ocr')),
    const StudentListScreen(key: ValueKey('student_list')),
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
    // Ensure navigation bar is visible after initialization
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
    // Force a rebuild when navigating away from this screen
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didPop() {
    super.didPop();
    // Force a rebuild when this screen is popped
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Force a rebuild when returning to this screen
    if (mounted) {
      setState(() {});
      // Force another rebuild to ensure navigation bar visibility
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
    // Force a rebuild when this screen is pushed
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner_outlined),
              activeIcon: Icon(Icons.document_scanner),
              label: 'Barcode',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.text_fields_outlined),
              activeIcon: Icon(Icons.text_fields),
              label: 'OCR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Mahasiswa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_outlined),
              activeIcon: Icon(Icons.access_time),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}