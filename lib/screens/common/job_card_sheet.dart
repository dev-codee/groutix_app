import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/launcher_helper.dart';
import '../../providers/leads_provider.dart';
import 'lead_chat_modal.dart';

class JobCardSheet extends StatelessWidget {
  final String leadId;

  const JobCardSheet({super.key, required this.leadId});

  static Future<void> show(BuildContext context, String leadId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => JobCardSheet(leadId: leadId),
    );
  }

  static const List<Map<String, String>> milestones = [
    {'label': 'Lead Received', 'status': 'New'},
    {'label': 'Contacted', 'status': 'Contacted'},
    {'label': 'Inspection Booked', 'status': 'Inspection Booked'},
    {'label': 'Inspection Done', 'status': 'Inspection Completed'},
    {'label': 'Quote Created', 'status': 'Quote Pending'},
    {'label': 'Quote Sent', 'status': 'Quote Sent'},
    {'label': 'Quote Accepted', 'status': 'Won'},
    {'label': 'Job Booked', 'status': 'Job Booked'},
    {'label': 'Job Done', 'status': 'Job Done'},
    {'label': 'Invoice Sent', 'status': 'Invoice Sent'},
    {'label': 'Payment Pending', 'status': 'Payment Pending'},
    {'label': 'Payment Received', 'status': 'Payment Received'},
    {'label': 'Warranty Sent', 'status': 'Warranty Sent'},
    {'label': 'Completed', 'status': 'Completed'},
  ];

  @override
  Widget build(BuildContext context) {
    final leadsProv = context.watch<LeadsProvider>();
    final lead = leadsProv.getLeadById(leadId);

    if (lead == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: Text('Job not found')),
      );
    }

    final currentIdx = milestones.indexWhere((m) => m['status'] == lead.status);
    final nextMilestone = currentIdx != -1 && currentIdx + 1 < milestones.length
        ? milestones[currentIdx + 1]
        : null;

    final quoteTotal = lead.quoteAmount != null && lead.quoteAmount! > 0
        ? DateFormatter.formatCurrency(lead.quoteAmount)
        : 'AUD \$0.00';

    final isWarrantyGiven = lead.warrantyProvided == true;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lead.jobNo != null ? 'JOB #${lead.jobNo}' : 'CLIENT JOB CARD',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            lead.createdAt != null
                                ? DateFormatter.formatRelative(lead.createdAt!)
                                : '',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lead.displayName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (lead.fullAddress.isNotEmpty)
                        Text(
                          lead.fullAddress,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Overview Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          label: 'CURRENT STAGE',
                          value: lead.status,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          label: 'JOB VALUE',
                          value: quoteTotal,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 0, height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          label: 'SERVICE TYPE',
                          value: lead.service ?? 'General Grout & Tile',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          label: 'WARRANTY STATUS',
                          value: isWarrantyGiven ? '🛡️ Provided' : '⚠️ Pending',
                          color: isWarrantyGiven ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Interactive Milestone Timeline
                  const Text(
                    'Pipeline Milestone Timeline',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: milestones.length,
                      itemBuilder: (ctx, i) {
                        final m = milestones[i];
                        final isPassed = currentIdx != -1 && i <= currentIdx;
                        final isCurrent = i == currentIdx;

                        return Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () {
                                    leadsProv.updateLeadField(lead.id, {'status': m['status']});
                                  },
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCurrent
                                          ? AppColors.primary
                                          : (isPassed ? AppColors.success : AppColors.cardAlt),
                                      border: Border.all(
                                        color: isCurrent
                                            ? AppColors.primary
                                            : (isPassed ? AppColors.success : AppColors.border),
                                        width: isCurrent ? 3 : 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: isPassed && !isCurrent
                                          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                                          : Text(
                                              '${i + 1}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: isCurrent
                                                    ? Colors.white
                                                    : (isPassed ? Colors.white : AppColors.textMuted),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 72,
                                  child: Text(
                                    m['label']!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                      color: isCurrent
                                          ? AppColors.primary
                                          : (isPassed ? AppColors.textPrimary : AppColors.textMuted),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (i < milestones.length - 1)
                              Container(
                                width: 20,
                                height: 2,
                                margin: const EdgeInsets.only(bottom: 22),
                                color: (currentIdx != -1 && i < currentIdx)
                                    ? AppColors.success
                                    : AppColors.border,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Workflow Next Action Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 6),
                            const Text(
                              'Next Pipeline Action',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          nextMilestone != null
                              ? 'Currently at "${lead.status}". Ready to advance to "${nextMilestone['label']}".'
                              : 'This client job is fully completed! 🏆',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                        ),
                        if (nextMilestone != null) ...[
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: () async {
                              final ok = await leadsProv.updateLeadField(
                                lead.id,
                                {'status': nextMilestone['status']},
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Advanced to ${nextMilestone['label']}!'
                                          : 'Failed to advance stage',
                                    ),
                                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: Text('Advance to ${nextMilestone['label']}'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Quick Contact & Coordination Actions
                  const Text('Customer Contact & Coordination', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (lead.phone != null && lead.phone!.isNotEmpty) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => LauncherHelper.makePhoneCall(lead.phone!),
                            icon: const Icon(Icons.call_rounded, size: 16),
                            label: const Text('Call'),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => LeadChatModal.show(context, lead.id),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                          label: const Text('Message'),
                        ),
                      ),
                      if (lead.fullAddress.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => LauncherHelper.openMapAddress(lead.fullAddress),
                            icon: const Icon(Icons.navigation_outlined, size: 16),
                            label: const Text('Navigate'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
