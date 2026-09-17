import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leads_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/tasks_provider.dart';
import '../common/lead_card.dart';
import '../common/notifications_screen.dart';
import '../common/status_pill.dart';
import '../common/team_chat_modal.dart';
import 'create_lead_modal.dart';
import 'manager_lead_detail_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;

  const ManagerDashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  bool _showTomorrowSchedule = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leads = context.read<LeadsProvider>();
      leads.fetchLeads();
      leads.fetchTeamUnread();
      leads.fetchStaff();
      context.read<TasksProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leadsProv = context.watch<LeadsProvider>();
    final tasksProv = context.watch<TasksProvider>();
    final notifsProv = context.watch<NotificationsProvider>();

    final leads = leadsProv.leads;
    final totalLeads = leads.length;

    final newLeadsCount = leads.where((l) => l.status == 'New' || l.status == 'Contacted').length;

    final inspCount = leads.where((l) => [
      'Inspection Booked', 'Inspection En Route', 'Inspection Arrived',
      'Inspection In Progress', 'Inspection Completed'
    ].contains(l.status)).length;

    final quoteCount = leads.where((l) => [
      'Quote Pending', 'Quote Sent', 'Negotiation', 'Won'
    ].contains(l.status)).length;

    final activeJobs = leads.where((l) => [
      'Job Booked', 'Scheduled', 'Job Confirmed', 'Job En Route',
      'Job Arrived', 'Job Started', 'Job In Progress'
    ].contains(l.status)).length;

    final completedJobs = leads.where((l) => l.status == 'Completed' || l.status == 'Job Done').length;
    final paymentPending = leads.where((l) => l.status == 'Invoice Sent' || l.status == 'Payment Pending').length;
    final warrantySent = leads.where((l) => l.status == 'Warranty Sent' || l.warrantyProvided == true).length;

    // Filter appointments for Today and Tomorrow
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    final todayAppointments = leads.where((l) {
      return DateFormatter.isSameDay(l.jobAt, now) || DateFormatter.isSameDay(l.inspectionAt, now);
    }).toList();

    final tomorrowAppointments = leads.where((l) {
      return DateFormatter.isSameDay(l.jobAt, tomorrow) || DateFormatter.isSameDay(l.inspectionAt, tomorrow);
    }).toList();

    final displayedAppointments = _showTomorrowSchedule ? tomorrowAppointments : todayAppointments;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${auth.currentUser?.displayName ?? "Manager"}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            Text(
              DateFormatter.formatTodayHeader(),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
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
            icon: Stack(
              children: [
                const Icon(Icons.forum_outlined),
                if (leadsProv.totalTeamUnread > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '${leadsProv.totalTeamUnread}',
                        style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Team Chat',
            onPressed: () => TeamChatModal.show(context),
          ),
          FilledButton.tonalIcon(
            onPressed: () => CreateLeadModal.show(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('New Lead'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              leadsProv.fetchLeads();
              leadsProv.fetchTeamUnread();
              tasksProv.fetchTasks();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await leadsProv.fetchLeads();
          await tasksProv.fetchTasks();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pipeline Quick Stats Bar (Horizontal Carousel)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickMetric(
                      label: 'Total Leads',
                      count: totalLeads,
                      icon: Icons.people_outline_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        leadsProv.setStatusFilter(null);
                        widget.onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickMetric(
                      label: 'New Leads',
                      count: newLeadsCount,
                      icon: Icons.add_circle_outline_rounded,
                      color: AppColors.success,
                      onTap: () {
                        leadsProv.setStatusFilter('New');
                        widget.onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickMetric(
                      label: 'Inspections',
                      count: inspCount,
                      icon: Icons.search_rounded,
                      color: AppColors.accent,
                      onTap: () {
                        leadsProv.setStatusFilter('Inspection Booked');
                        widget.onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickMetric(
                      label: 'Quotes',
                      count: quoteCount,
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.warning,
                      onTap: () {
                        leadsProv.setStatusFilter('Quote Pending');
                        widget.onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickMetric(
                      label: 'Field Jobs',
                      count: activeJobs,
                      icon: Icons.engineering_rounded,
                      color: Colors.deepOrange,
                      onTap: () {
                        leadsProv.setStatusFilter('Job In Progress');
                        widget.onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickMetric(
                      label: 'Done',
                      count: completedJobs,
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                      onTap: () {
                        leadsProv.setStatusFilter('Job Done');
                        widget.onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickMetric(
                      label: 'Payment Due',
                      count: paymentPending,
                      icon: Icons.payment_rounded,
                      color: AppColors.danger,
                      onTap: () {
                        leadsProv.setStatusFilter('Invoice Sent');
                        widget.onNavigateTab(1);
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildQuickMetric(
                      label: 'Warranty',
                      count: warrantySent,
                      icon: Icons.shield_outlined,
                      color: AppColors.purple,
                      onTap: () {
                        leadsProv.setStatusFilter('Warranty Sent');
                        widget.onNavigateTab(1);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Today's & Tomorrow's Field Schedule Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Schedule Header with Segmented Toggle
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Text(
                                'Field Schedule',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${displayedAppointments.length}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          // Toggle Buttons: Today / Tomorrow
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Row(
                              children: [
                                _buildScheduleTabBtn(
                                  title: 'Today',
                                  isSelected: !_showTomorrowSchedule,
                                  onTap: () => setState(() => _showTomorrowSchedule = false),
                                ),
                                _buildScheduleTabBtn(
                                  title: 'Tomorrow',
                                  isSelected: _showTomorrowSchedule,
                                  onTap: () => setState(() => _showTomorrowSchedule = true),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Appointments List
                    if (displayedAppointments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.event_available_rounded, size: 32, color: AppColors.textMuted),
                              const SizedBox(height: 6),
                              Text(
                                _showTomorrowSchedule
                                    ? 'No inspections or jobs scheduled for tomorrow.'
                                    : 'No inspections or jobs scheduled for today.',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayedAppointments.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 14, endIndent: 14),
                        itemBuilder: (ctx, i) {
                          final appt = displayedAppointments[i];
                          final isInsp = appt.inspectionAt != null &&
                              DateFormatter.isSameDay(
                                appt.inspectionAt,
                                _showTomorrowSchedule ? tomorrow : now,
                              );
                          final apptTime = isInsp ? appt.inspectionAt : appt.jobAt;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManagerLeadDetailScreen(leadId: appt.id),
                                ),
                              );
                            },
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isInsp ? Colors.blue.shade50 : Colors.deepOrange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isInsp ? Colors.blue.shade200 : Colors.deepOrange.shade200,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isInsp ? Icons.search_rounded : Icons.engineering_rounded,
                                    size: 14,
                                    color: isInsp ? Colors.blue.shade800 : Colors.deepOrange.shade800,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormatter.formatApptTime(apptTime),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isInsp ? Colors.blue.shade900 : Colors.deepOrange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  appt.displayName,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  appt.displayJobNo,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              [
                                if (appt.address != null && appt.address!.isNotEmpty) appt.fullAddress,
                                if (appt.technician != null && appt.technician!.isNotEmpty) 'Tech: ${appt.technician}',
                              ].join(' • '),
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: StatusPill(status: appt.status),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Operations To-Do List Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.purpleBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.checklist_rounded, color: AppColors.purple, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Operational Tasks',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${tasksProv.pendingCount} pending items for today',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => widget.onNavigateTab(2),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(70, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('View'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Recent Active Leads Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Customer Leads',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  TextButton(
                    onPressed: () {
                      leadsProv.setStatusFilter(null);
                      widget.onNavigateTab(1);
                    },
                    child: Text('View All (${leads.length}) →'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (leadsProv.isLoading && leads.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (leadsProv.errorMessage != null && leads.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.dangerBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: AppColors.danger, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          leadsProv.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => leadsProv.fetchLeads(),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            minimumSize: const Size(100, 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (leads.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No leads found.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: leads.take(8).length,
                  itemBuilder: (ctx, i) {
                    final lead = leads[i];
                    return LeadCard(
                      lead: lead,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManagerLeadDetailScreen(leadId: lead.id),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMetric({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                Text(
                  '$count',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTabBtn({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
