import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_notification_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../inspection/inspection_visit_screen.dart';
import '../manager/manager_lead_detail_screen.dart';
import '../technician/technician_job_screen.dart';
import 'lead_chat_modal.dart';
import 'team_chat_modal.dart';

class InAppNotificationBanner extends StatelessWidget {
  final Widget child;

  const InAppNotificationBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final notifsProv = context.watch<NotificationsProvider>();
    final banner = notifsProv.activeInAppBanner;

    return Stack(
      children: [
        child,
        if (banner != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            right: 12,
            child: _BannerCard(notification: banner),
          ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final AppNotificationModel notification;

  const _BannerCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final notifsProv = context.read<NotificationsProvider>();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.up,
      onDismissed: (_) => notifsProv.dismissInAppBanner(),
      child: Material(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surface,
        child: InkWell(
          onTap: () {
            notifsProv.markAsRead(notification.id);
            notifsProv.dismissInAppBanner();
            _navigate(context, notification, auth.currentRole);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                  onPressed: () => notifsProv.dismissInAppBanner(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigate(
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
