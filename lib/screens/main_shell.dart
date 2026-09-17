import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'common/profile_screen.dart';
import 'finance/finance_home_screen.dart';
import 'inspection/inspection_home_screen.dart';
import 'manager/manager_dashboard_screen.dart';
import 'manager/manager_leads_screen.dart';
import 'manager/manager_tasks_screen.dart';
import 'technician/technician_home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onNavigateTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.currentRole;

    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    switch (role) {
      case UserRole.manager:
      case UserRole.superAdmin:
      case UserRole.intake:
        screens = [
          ManagerDashboardScreen(onNavigateTab: _onNavigateTab),
          const ManagerLeadsScreen(),
          const ManagerTasksScreen(),
          const ProfileScreen(),
        ];
        navItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_kanban_rounded),
            label: 'Pipeline',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ];
        break;

      case UserRole.inspection:
        screens = const [
          InspectionHomeScreen(),
          ProfileScreen(),
        ];
        navItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_rounded),
            label: 'Inspections',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ];
        break;

      case UserRole.technician:
        screens = const [
          TechnicianHomeScreen(),
          ProfileScreen(),
        ];
        navItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.engineering_rounded),
            label: 'My Jobs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ];
        break;

      case UserRole.finance:
        screens = const [
          FinanceHomeScreen(),
          ProfileScreen(),
        ];
        navItems = const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Invoices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ];
        break;
    }

    // Guard against index out of range when switching roles
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: navItems,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 0,
        ),
      ),
    );
  }
}
