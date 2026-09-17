import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_helper.dart';
import '../../providers/leads_provider.dart';
import '../common/job_card_sheet.dart';
import '../common/lead_chat_modal.dart';
import '../common/status_pill.dart';
import '../common/team_chat_modal.dart';
import 'inspection_form_screen.dart';
import 'inspection_photos_screen.dart';

class InspectionVisitScreen extends StatefulWidget {
  final String leadId;

  const InspectionVisitScreen({super.key, required this.leadId});

  @override
  State<InspectionVisitScreen> createState() => _InspectionVisitScreenState();
}

class _InspectionVisitScreenState extends State<InspectionVisitScreen> {
  bool _actionLoading = false;

  Future<void> _handleOnTheWay() async {
    setState(() => _actionLoading = true);
    final leadsProv = context.read<LeadsProvider>();
    final result = await leadsProv.notifyOnTheWay(widget.leadId, eventType: 'en_route');
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
                ? 'SMS and email sent to the client with estimated arrival time: $eta.'
                : 'SMS and email sent to client notifying them you are on the way.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send On-The-Way notification.')),
      );
    }
  }

  Future<void> _handleReached() async {
    setState(() => _actionLoading = true);
    final leadsProv = context.read<LeadsProvider>();
    final result = await leadsProv.notifyOnTheWay(widget.leadId, eventType: 'arrived');
    setState(() => _actionLoading = false);

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as Reached! Client has been notified.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleStartInspection() async {
    final leadsProv = context.read<LeadsProvider>();
    await leadsProv.updateLeadField(widget.leadId, {'status': 'Inspection In Progress'});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection is now In Progress.'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  Future<void> _handleCompleteInspection() async {
    final leadsProv = context.read<LeadsProvider>();
    final success = await leadsProv.updateLeadField(widget.leadId, {'status': 'Inspection Completed'});
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection Completed! Handed back to Intake for quoting.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final leadsProv = context.watch<LeadsProvider>();
    final lead = leadsProv.getLeadById(widget.leadId);

    if (lead == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inspection Visit')),
        body: const Center(child: Text('Visit record not found.')),
      );
    }

    final isEnRoute = lead.status == 'Inspection En Route';
    final isArrived = lead.status == 'Inspection Arrived';
    final isInProgress = lead.status == 'Inspection In Progress';
    final isCompleted = lead.status == 'Inspection Completed' || lead.inspectionReport?.status == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: Text('${lead.displayJobNo} Visit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Job Card',
            onPressed: () => JobCardSheet.show(context, lead.id),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Message Customer',
            onPressed: () => LeadChatModal.show(context, lead.id),
          ),
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: 'Team Chat / Office',
            onPressed: () => TeamChatModal.show(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Property & Client Overview
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

                  // Full Address with One-Tap Maps Button
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

                  // Phone and WhatsApp Actions
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

            // Property Specifics & Reported Defects
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
                    'Reported Issues & Inspection Scope',
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
                        const Text('Areas to Inspect: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
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
                        const Text('Active Leakage: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
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
                  if (lead.notes != null && lead.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Client Remarks: ${lead.notes!}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Step-by-Step Field Visit Action Journey
            const Text(
              'Field Visit Workflow',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // Step 1: On The Way
            _buildActionStep(
              stepNumber: '1',
              title: 'On The Way (En Route)',
              subtitle: 'Sends SMS & Email to customer with live GPS ETA',
              icon: Icons.directions_car_rounded,
              isActive: isEnRoute,
              isDone: isArrived || isInProgress || isCompleted,
              actionWidget: ElevatedButton.icon(
                onPressed: _actionLoading ? null : _handleOnTheWay,
                icon: const Icon(Icons.near_me_rounded, size: 16),
                label: Text(isEnRoute ? 'Update ETA' : 'I am on the way'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnRoute ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Step 2: Arrived
            _buildActionStep(
              stepNumber: '2',
              title: 'Reached / Arrived',
              subtitle: 'Notifies customer that you are on site',
              icon: Icons.pin_drop_rounded,
              isActive: isArrived,
              isDone: isInProgress || isCompleted,
              actionWidget: ElevatedButton.icon(
                onPressed: _actionLoading ? null : _handleReached,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('I have arrived'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isArrived ? AppColors.success : AppColors.cardAlt,
                  foregroundColor: isArrived ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Step 3: Start Inspection
            _buildActionStep(
              stepNumber: '3',
              title: 'Start Inspection',
              subtitle: 'Begin physical site check',
              icon: Icons.play_arrow_rounded,
              isActive: isInProgress,
              isDone: isCompleted,
              actionWidget: ElevatedButton.icon(
                onPressed: _handleStartInspection,
                icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
                label: const Text('Start Inspection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInProgress ? AppColors.info : AppColors.cardAlt,
                  foregroundColor: isInProgress ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Step 4: Digital Form & Photos Hub
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
                    'Step 4: Inspection Evidence & Findings',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill out the 8-section inspection report and take before photos.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InspectionFormScreen(lead: lead),
                              ),
                            );
                          },
                          icon: const Icon(Icons.checklist_rounded, size: 16),
                          label: const Text('Digital Form'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InspectionPhotosScreen(leadId: lead.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.photo_camera_rounded, size: 16),
                          label: Text('Photos (${lead.photos.length})'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step 5: Mark Completed
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.successBg : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isCompleted ? AppColors.successBorder : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step 5: Completion & Handoff',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Completes inspection and automatically returns lead to Intake to build quote.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: isCompleted ? null : _handleCompleteInspection,
                    icon: const Icon(Icons.task_alt_rounded, size: 16),
                    label: Text(isCompleted ? 'Inspection Completed' : 'Complete Inspection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      disabledBackgroundColor: AppColors.success.withValues(alpha: 0.4),
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

  Widget _buildActionStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required bool isDone,
    required Widget actionWidget,
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
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.success
                      : isActive
                          ? AppColors.primary
                          : AppColors.cardAlt,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : Text(
                          stepNumber,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isActive ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          actionWidget,
        ],
      ),
    );
  }
}
