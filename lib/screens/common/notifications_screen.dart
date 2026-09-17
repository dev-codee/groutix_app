import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/app_notification_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../inspection/inspection_visit_screen.dart';
import '../manager/manager_lead_detail_screen.dart';
import '../technician/technician_job_screen.dart';
import 'empty_state.dart';
import 'lead_chat_modal.dart';
import 'team_chat_modal.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'all'; // 'all', 'lead', 'message', 'team', 'finance'

  @override
  Widget build(BuildContext context) {
    final notifsProv = context.watch<NotificationsProvider>();
    final auth = context.watch<AuthProvider>();
    final allNotifications = notifsProv.notifications;

    final filtered = allNotifications.where((n) {
      if (_filter == 'all') return true;
      return n.category == _filter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w900)),
            if (notifsProv.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${notifsProv.unreadCount} new',
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (allNotifications.isNotEmpty) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'mark_all_read') {
                  notifsProv.markAllAsRead();
                } else if (val == 'clear_all') {
                  notifsProv.clearAll();
                } else if (val == 'test_alert') {
                  notifsProv.dispatchTestNotification();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'test_alert',
                  child: Row(
                    children: [
                      Icon(Icons.notification_add_rounded, size: 18, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Send test alert'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Clear all notifications', style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', allNotifications.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Leads 🔔',
                  'lead',
                  allNotifications.where((n) => n.category == 'lead').length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Messages 💬',
                  'message',
                  allNotifications.where((n) => n.category == 'message').length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Team 👥',
                  'team',
                  allNotifications.where((n) => n.category == 'team').length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Finance 💰',
                  'finance',
                  allNotifications.where((n) => n.category == 'finance').length,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Notification List
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'All Caught Up',
                    message: 'No notifications in this view.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: 68),
                    itemBuilder: (ctx, i) {
                      final notif = filtered[i];
                      return Dismissible(
                        key: Key(notif.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.danger,
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          notifsProv.removeNotification(notif.id);
                        },
                        child: _buildNotificationTile(context, notif, notifsProv, auth.currentRole),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.cardAlt,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    AppNotificationModel notif,
    NotificationsProvider notifsProv,
    UserRole currentRole,
  ) {
    final (icon, color, bg) = _categoryIconAndColor(notif.category);

    return InkWell(
      onTap: () {
        notifsProv.markAsRead(notif.id);
        _handleNotificationNavigation(context, notif, currentRole);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notif.isRead ? Colors.transparent : AppColors.primaryLight.withValues(alpha: 0.15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Icon Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormatter.formatRelative(notif.timestamp.toIso8601String()),
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _categoryIconAndColor(String category) {
    switch (category) {
      case 'lead':
        return (Icons.person_add_rounded, AppColors.success, AppColors.successBg);
      case 'message':
        return (Icons.chat_bubble_rounded, AppColors.accent, AppColors.cardAlt);
      case 'team':
        return (Icons.groups_rounded, AppColors.primary, AppColors.primaryLight);
      case 'finance':
        return (Icons.payments_rounded, Colors.teal, Colors.teal.shade50);
      case 'schedule':
      default:
        return (Icons.calendar_today_rounded, AppColors.warning, AppColors.warningBg);
    }
  }

  void _handleNotificationNavigation(
    BuildContext context,
    AppNotificationModel notif,
    UserRole currentRole,
  ) {
    if (notif.leadId != null && notif.leadId!.isNotEmpty) {
      if (notif.category == 'message') {
        LeadChatModal.show(context, notif.leadId!);
      } else {
        switch (currentRole) {
          case UserRole.technician:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TechnicianJobScreen(leadId: notif.leadId!)),
            );
            break;
          case UserRole.inspection:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => InspectionVisitScreen(leadId: notif.leadId!)),
            );
            break;
          default:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ManagerLeadDetailScreen(leadId: notif.leadId!)),
            );
            break;
        }
      }
    } else if (notif.targetUsername != null && notif.targetUsername!.isNotEmpty) {
      TeamChatModal.show(context, username: notif.targetUsername!);
    }
  }
}
