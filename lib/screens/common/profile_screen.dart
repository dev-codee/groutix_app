import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showRoleSwitcher(BuildContext context) {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Switch Role Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...[
              UserRole.manager,
              UserRole.inspection,
              UserRole.technician,
              UserRole.finance,
            ].map((role) {
              final isCurrent = auth.currentRole == role;
              return ListTile(
                title: Text(role.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                leading: Icon(
                  isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isCurrent ? AppColors.primary : AppColors.textMuted,
                ),
                onTap: () {
                  auth.switchRoleForTesting(role);
                  Navigator.of(ctx).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user?.displayName.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Staff Member',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user?.username ?? "username"}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user?.role.label ?? 'Staff',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Role Switcher Tile
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
              title: const Text('Switch Role Experience', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Currently active: ${user?.role.label}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showRoleSwitcher(context),
            ),
          ),
          const SizedBox(height: 12),

          // Notifications & Alerts Center Tile
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Consumer<NotificationsProvider>(
              builder: (ctx, notifsProv, _) {
                return ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                  title: const Text('Notifications & Alerts Center', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    notifsProv.unreadCount > 0
                        ? '${notifsProv.unreadCount} unread notification${notifsProv.unreadCount > 1 ? "s" : ""}'
                        : 'System alerts, leads, and chat messages',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (notifsProv.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${notifsProv.unreadCount}',
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                  onTap: () => NotificationsScreen.show(context),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Test Notification Button Tile
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: const Icon(Icons.bolt_rounded, color: AppColors.warning),
              title: const Text('Test Notification Alert', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Trigger test lead alert with sound & banner'),
              trailing: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
              onTap: () {
                context.read<NotificationsProvider>().dispatchTestNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification dispatched! Check your status bar and top banner.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Server Config Info Tile
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: const Icon(Icons.cloud_outlined, color: AppColors.textSecondary),
              title: const Text('Connected Backend Host', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(AppConfig.baseUrl),
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton.icon(
            onPressed: () => auth.logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 16),

          const Center(
            child: Text(
              'Groutix v1.0.0',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
