import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_helper.dart';
import '../../providers/leads_provider.dart';
import '../common/lead_chat_modal.dart';
import '../common/status_pill.dart';
import '../inspection/inspection_photos_screen.dart';

class TechnicianJobScreen extends StatefulWidget {
  final String leadId;

  const TechnicianJobScreen({super.key, required this.leadId});

  @override
  State<TechnicianJobScreen> createState() => _TechnicianJobScreenState();
}

class _TechnicianJobScreenState extends State<TechnicianJobScreen> {
  bool _actionLoading = false;

  Future<void> _handleOnTheWay() async {
    setState(() => _actionLoading = true);
    final leadsProv = context.read<LeadsProvider>();
    final result = await leadsProv.notifyTechnicianOnTheWay(widget.leadId, eventType: 'en_route');
    setState(() => _actionLoading = false);

    if (!mounted) return;

    if (result != null) {
      final eta = result['eta'];
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.navigation_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Client Notified'),
            ],
          ),
          content: Text(
            eta != null
                ? 'Client notified: Specialist is on the way with ETA: $eta.'
                : 'Client notified: Specialist is on the way.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleReached() async {
    setState(() => _actionLoading = true);
    final leadsProv = context.read<LeadsProvider>();
    final result = await leadsProv.notifyTechnicianOnTheWay(widget.leadId, eventType: 'arrived');
    setState(() => _actionLoading = false);

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as Reached! Customer has been notified.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleStartJob({int totalDays = 1}) async {
    final leadsProv = context.read<LeadsProvider>();
    await leadsProv.updateLeadField(widget.leadId, {
      'status': 'Job Started',
      'jobTotalDays': totalDays,
      'jobDaysDone': 1,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job started!'), backgroundColor: AppColors.info),
      );
    }
  }

  Future<void> _handleJobDone() async {
    final leadsProv = context.read<LeadsProvider>();
    final success = await leadsProv.updateLeadField(widget.leadId, {'status': 'Job Done'});
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job marked as Done! Handed over to Finance.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _showStartJobDialog() {
    int selectedDays = 1;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Start Work Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How many days will this job take on site?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3, 4, 5].map((d) {
                  final isSel = selectedDays == d;
                  return ChoiceChip(
                    label: Text('$d ${d == 1 ? "Day" : "Days"}'),
                    selected: isSel,
                    onSelected: (_) => setDlgState(() => selectedDays = d),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _handleStartJob(totalDays: selectedDays);
              },
              child: const Text('Start Now'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsProv = context.watch<LeadsProvider>();
    final lead = leadsProv.getLeadById(widget.leadId);

    if (lead == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Order')),
        body: const Center(child: Text('Job not found.')),
      );
    }

    final isEnRoute = lead.status == 'Job En Route';
    final isArrived = lead.status == 'Job Arrived';
    final isStarted = lead.status == 'Job Started' || lead.status == 'Job In Progress';
    final isDone = lead.status == 'Job Done' || lead.status == 'Completed';

    return Scaffold(
      appBar: AppBar(
        title: Text('${lead.displayJobNo} Execution'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Client & Job Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lead.displayJobNo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      StatusPill(status: lead.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lead.displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  // Scheduled Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        lead.displayScheduleTime,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Address
                  InkWell(
                    onTap: () => LauncherHelper.openMapAddress(lead.fullAddress),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lead.fullAddress,
                            style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary),
                          ),
                        ),
                        const Icon(Icons.navigation_rounded, size: 16, color: AppColors.accent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Contact actions
                  Row(
                    children: [
                      if (lead.phone != null) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => LauncherHelper.makePhoneCall(lead.phone),
                            icon: const Icon(Icons.call_rounded, size: 15),
                            label: const Text('Call Client'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => LeadChatModal.show(context, lead.id, initialChannel: 'sms'),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                            label: const Text('Chat'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scope of Work Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work Order Scope & Property Details',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (lead.service != null && lead.service!.isNotEmpty)
                    Text(
                      lead.service!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  if (lead.areas != null && lead.areas!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Areas / Rooms: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        Expanded(child: Text(lead.areas!, style: const TextStyle(fontSize: 12.5))),
                      ],
                    ),
                  ],
                  if (lead.damagedTiles != null && lead.damagedTiles!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Damaged Tiles: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        Expanded(child: Text(lead.damagedTiles!, style: const TextStyle(fontSize: 12.5))),
                      ],
                    ),
                  ],
                  if (lead.leaking != null && lead.leaking!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Leaking Issue: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: lead.leaking!.toLowerCase() != 'no' ? AppColors.dangerBg : AppColors.cardAlt,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lead.leaking!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: lead.leaking!.toLowerCase() != 'no' ? AppColors.danger : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (lead.quoteScope != null && lead.quoteScope!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lead.quoteScope!,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
                      ),
                    ),
                  ],
                  if (lead.notes != null && lead.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Customer Notes: ${lead.notes}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  if (lead.quoteItems.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Deliverable Items:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    ...lead.quoteItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${item.service ?? item.description ?? "Task"} (${item.qty}x)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Field Execution Journey
            const Text(
              'Job Execution Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // 1: On The Way
            _buildActionCard(
              title: '1. On The Way',
              subtitle: 'Sends live GPS ETA SMS/email to customer',
              isActive: isEnRoute,
              isDone: isArrived || isStarted || isDone,
              child: ElevatedButton.icon(
                onPressed: _actionLoading ? null : _handleOnTheWay,
                icon: const Icon(Icons.near_me_rounded, size: 16),
                label: Text(isEnRoute ? 'Update ETA' : 'I am on the way'),
              ),
            ),
            const SizedBox(height: 12),

            // 2: Reached
            _buildActionCard(
              title: '2. Reached Site',
              subtitle: 'Marks arrival and sends arrival notice',
              isActive: isArrived,
              isDone: isStarted || isDone,
              child: ElevatedButton.icon(
                onPressed: _actionLoading ? null : _handleReached,
                icon: const Icon(Icons.pin_drop_rounded, size: 16),
                label: const Text('I have arrived on site'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isArrived ? AppColors.success : AppColors.cardAlt,
                  foregroundColor: isArrived ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3: Start Job & Multi-day progress
            _buildActionCard(
              title: '3. Start Job',
              subtitle: lead.jobTotalDays != null && lead.jobTotalDays! > 1
                  ? 'Day ${lead.jobDaysDone ?? 1} of ${lead.jobTotalDays}'
                  : 'Commence physical work',
              isActive: isStarted,
              isDone: isDone,
              child: isStarted && lead.jobTotalDays != null && lead.jobTotalDays! > 1
                  ? Column(
                      children: [
                        LinearProgressIndicator(
                          value: ((lead.jobDaysDone ?? 1) / lead.jobTotalDays!),
                          backgroundColor: AppColors.cardAlt,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            final nextDay = (lead.jobDaysDone ?? 1) + 1;
                            if (nextDay > lead.jobTotalDays!) {
                              _handleJobDone();
                            } else {
                              leadsProv.updateLeadField(widget.leadId, {'jobDaysDone': nextDay});
                            }
                          },
                          child: Text(
                            (lead.jobDaysDone ?? 1) >= lead.jobTotalDays!
                                ? 'Finish All Days & Complete'
                                : 'Complete Day ${lead.jobDaysDone ?? 1}',
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: isDone ? null : _showStartJobDialog,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(isStarted ? 'Job In Progress' : 'Start Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isStarted ? AppColors.info : AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            // 4: Photos Hub
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Work Evidence Photos',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${lead.photos.length} photos uploaded',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InspectionPhotosScreen(leadId: lead.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.photo_camera_rounded, size: 16),
                    label: const Text('Add Photos'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 40),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5: Job Done Handoff
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDone ? AppColors.successBg : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDone ? AppColors.successBorder : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step 5: Job Completion & Finance Handoff',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Marks execution done and automatically notifies Finance to issue invoice.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: isDone ? null : _handleJobDone,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(isDone ? 'Job Completed' : 'Job Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor: AppColors.success.withValues(alpha: 0.4),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isDone,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary : isDone ? AppColors.successBorder : AppColors.border,
          width: isActive ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              if (isDone)
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
