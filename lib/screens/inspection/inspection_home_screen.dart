import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leads_provider.dart';
import '../../providers/notifications_provider.dart';
import '../common/empty_state.dart';
import '../common/lead_card.dart';
import '../common/notifications_screen.dart';
import '../common/team_chat_modal.dart';
import 'inspection_visit_screen.dart';

class InspectionHomeScreen extends StatefulWidget {
  const InspectionHomeScreen({super.key});

  @override
  State<InspectionHomeScreen> createState() => _InspectionHomeScreenState();
}

class _InspectionHomeScreenState extends State<InspectionHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadsProvider>().fetchLeads();
      context.read<LeadsProvider>().fetchTeamUnread();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leadsProv = context.watch<LeadsProvider>();
    final notifsProv = context.watch<NotificationsProvider>();
    final inspections = leadsProv.getScopedLeads(UserRole.inspection);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, ${auth.currentUser?.displayName ?? "Inspector"}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (notifsProv.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '${notifsProv.unreadCount}',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () => NotificationsScreen.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Team Chat / Office',
            onPressed: () => TeamChatModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              leadsProv.fetchLeads();
              leadsProv.fetchTeamUnread();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => leadsProv.fetchLeads(),
        child: inspections.isEmpty && !leadsProv.isLoading
            ? const EmptyState(
                icon: Icons.assignment_turned_in_outlined,
                title: 'No Inspections Queued',
                message: 'No scheduled inspections pending.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: inspections.length,
                itemBuilder: (ctx, i) {
                  final lead = inspections[i];
                  return LeadCard(
                    lead: lead,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InspectionVisitScreen(leadId: lead.id),
                        ),
                      );
                    },
                    trailingAction: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InspectionVisitScreen(leadId: lead.id),
                          ),
                        );
                      },
                      icon: const Icon(Icons.assignment_outlined, size: 14),
                      label: const Text('Manage Visit'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
