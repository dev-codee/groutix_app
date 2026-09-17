import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/launcher_helper.dart';
import '../../providers/leads_provider.dart';
import '../common/edit_quote_modal.dart';
import '../common/job_card_sheet.dart';
import '../common/lead_chat_modal.dart';
import '../common/photo_viewer_modal.dart';
import '../common/status_pill.dart';
import '../common/team_chat_modal.dart';
import '../finance/issue_warranty_sheet.dart';
import '../finance/record_payment_dialog.dart';
import '../finance/send_invoice_sheet.dart';

class ManagerLeadDetailScreen extends StatefulWidget {
  final String leadId;

  const ManagerLeadDetailScreen({super.key, required this.leadId});

  @override
  State<ManagerLeadDetailScreen> createState() => _ManagerLeadDetailScreenState();
}

class _ManagerLeadDetailScreenState extends State<ManagerLeadDetailScreen> {
  final _picker = ImagePicker();

  final List<String> _canonicalStages = [
    'New',
    'Contacted',
    'Waiting for Info',
    'Inspection Booked',
    'Inspection En Route',
    'Inspection Arrived',
    'Inspection In Progress',
    'Inspection Completed',
    'Quote Pending',
    'Quote Sent',
    'Negotiation',
    'Won',
    'Job Booked',
    'Scheduled',
    'Job Confirmed',
    'Job En Route',
    'Job Arrived',
    'Job Started',
    'Job In Progress',
    'Job Done',
    'Invoice Sent',
    'Payment Pending',
    'Payment Received',
    'Warranty Sent',
    'Completed',
    'Lost',
  ];

  Future<void> _handleStatusChange(String newStatus) async {
    final leadsProv = context.read<LeadsProvider>();
    final success = await leadsProv.updateLeadField(widget.leadId, {'status': newStatus});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Status updated to $newStatus' : 'Failed to update status'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleLogCall(String outcome) async {
    final leadsProv = context.read<LeadsProvider>();
    final success = await leadsProv.logCall(widget.leadId, outcome);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Logged call: $outcome' : 'Failed to log call'),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pickDateTime({
    required String title,
    required String initialValue,
    required Function(String isoString) onSelected,
  }) async {
    DateTime initial = DateTime.tryParse(initialValue) ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) return;

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    onSelected(dt.toIso8601String());
  }

  Future<void> _handleUploadPhotos() async {
    final leadsProv = context.read<LeadsProvider>();
    final images = await _picker.pickMultiImage();
    if (images.isEmpty) return;

    final success = await leadsProv.uploadPhotos(widget.leadId, images);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Uploaded ${images.length} photo(s)' : 'Upload failed'),
        backgroundColor: success ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsProv = context.watch<LeadsProvider>();
    final lead = leadsProv.getLeadById(widget.leadId);

    if (lead == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead Details')),
        body: const Center(child: Text('Lead not found')),
      );
    }

    final hasQuoteItems = lead.quoteItems.isNotEmpty;
    final isLeaking = lead.leaking != null &&
        lead.leaking!.trim().isNotEmpty &&
        lead.leaking!.toLowerCase() != 'no';

    return Scaffold(
      appBar: AppBar(
        title: Text(lead.displayJobNo),
        actions: [
          FilledButton.tonalIcon(
            onPressed: () => JobCardSheet.show(context, lead.id),
            icon: const Icon(Icons.badge_outlined, size: 16),
            label: const Text('Job Card'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Customer Messages',
            onPressed: () => LeadChatModal.show(context, lead.id),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => leadsProv.fetchLeads(silent: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Client Contact Card
            _buildSectionCard(
              title: 'Client Information',
              icon: Icons.person_rounded,
              trailing: StatusPill(status: lead.status),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  if (lead.customerType != null || lead.agency != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (lead.customerType != null && lead.customerType!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lead.customerType!,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                        if (lead.agency != null && lead.agency!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Agency: ${lead.agency!}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Phone & Direct Contact Buttons
                  if (lead.phone != null && lead.phone!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          lead.phone!,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        FilledButton.tonalIcon(
                          onPressed: () => LauncherHelper.makePhoneCall(lead.phone),
                          icon: const Icon(Icons.call_rounded, size: 15),
                          label: const Text('Call'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () => LeadChatModal.show(context, lead.id),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                          label: const Text('Chat'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Email
                  if (lead.email != null && lead.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lead.email!,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Full Property Address
                  if (lead.address != null && lead.address!.isNotEmpty)
                    InkWell(
                      onTap: () => LauncherHelper.openMapAddress(lead.fullAddress),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lead.fullAddress,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.navigation_outlined, size: 15, color: AppColors.accent),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Tenants (if present)
            if (lead.tenants.isNotEmpty) ...[
              _buildSectionCard(
                title: 'Tenants / Occupants (${lead.tenants.length})',
                icon: Icons.people_outline_rounded,
                child: Column(
                  children: lead.tenants.map((t) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                Text(t.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                if (t.email != null && t.email!.isNotEmpty)
                                  Text(t.email!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call_rounded, size: 18, color: AppColors.primary),
                            onPressed: () => LauncherHelper.makePhoneCall(t.phone),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.accent),
                            onPressed: () => LauncherHelper.showMessageOptions(context, t.phone, name: t.name),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 3. Pipeline Stage & Log Call
            _buildSectionCard(
              title: 'Pipeline & Staff Actions',
              icon: Icons.alt_route_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update Stage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _canonicalStages.contains(lead.status) ? lead.status : null,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: _canonicalStages.map((st) {
                      return DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null && val != lead.status) {
                        _handleStatusChange(val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  const Text('Log Phone Call Outcome', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildCallChip('Connected', Icons.call_rounded, AppColors.success),
                      _buildCallChip('Call Attempted', Icons.phone_forwarded_rounded, AppColors.textSecondary),
                      _buildCallChip('No Answer', Icons.phone_missed_rounded, AppColors.danger),
                      _buildCallChip('Callback Requested', Icons.phone_callback_rounded, AppColors.primary),
                      _buildCallChip('Customer Interested', Icons.thumb_up_rounded, AppColors.success),
                      _buildCallChip('Not Interested', Icons.thumb_down_rounded, AppColors.danger),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 4. Property & Problem Specifics
            _buildSectionCard(
              title: 'Property & Work Details',
              icon: Icons.home_repair_service_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Service Required', lead.service ?? 'General Grout & Tile Service', isBold: true),
                  if (lead.areas != null && lead.areas!.isNotEmpty)
                    _buildDetailRow('Areas / Rooms', lead.areas!),
                  if (lead.damagedTiles != null && lead.damagedTiles!.isNotEmpty)
                    _buildDetailRow('Damaged / Cracked Tiles', lead.damagedTiles!),
                  if (lead.leaking != null && lead.leaking!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 130,
                            child: Text('Leaking Issue:', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLeaking ? AppColors.dangerBg : AppColors.cardAlt,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isLeaking ? AppColors.dangerBorder : AppColors.border),
                            ),
                            child: Text(
                              lead.leaking!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isLeaking ? AppColors.danger : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (lead.notes != null && lead.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Customer Notes & Requests:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(lead.notes!, style: const TextStyle(fontSize: 13, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 5. Scheduling & Staffing Card
            _buildSectionCard(
              title: 'Schedule & Staffing',
              icon: Icons.calendar_today_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inspection Time
                  _buildScheduleRow(
                    label: 'Inspection Booking',
                    value: lead.inspectionAt != null && lead.inspectionAt!.isNotEmpty
                        ? DateFormatter.formatAppt(lead.inspectionAt!)
                        : 'Not Scheduled',
                    icon: Icons.search_rounded,
                    onEdit: () {
                      _pickDateTime(
                        title: 'Inspection Appointment',
                        initialValue: lead.inspectionAt ?? '',
                        onSelected: (iso) => leadsProv.updateLeadField(lead.id, {'inspectionAt': iso}),
                      );
                    },
                  ),
                  const Divider(height: 16),

                  // Job Execution Time
                  _buildScheduleRow(
                    label: 'Job Execution',
                    value: lead.jobAt != null && lead.jobAt!.isNotEmpty
                        ? DateFormatter.formatAppt(lead.jobAt!)
                        : 'Not Scheduled',
                    icon: Icons.engineering_rounded,
                    onEdit: () {
                      _pickDateTime(
                        title: 'Job Execution Appointment',
                        initialValue: lead.jobAt ?? '',
                        onSelected: (iso) => leadsProv.updateLeadField(lead.id, {'jobAt': iso}),
                      );
                    },
                  ),
                  const Divider(height: 16),

                  // Staff & Technician
                  _buildDetailRow(
                    'Assigned Staff',
                    lead.assigned ?? 'Unassigned',
                    trailing: (lead.assigned != null &&
                            lead.assigned!.isNotEmpty &&
                            lead.assigned!.toLowerCase() != 'unassigned')
                        ? InkWell(
                            onTap: () => TeamChatModal.show(
                              context,
                              username: lead.assigned,
                              name: lead.assigned,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text('Chat', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                  _buildDetailRow(
                    'Field Technician',
                    lead.technician ?? 'Unassigned',
                    trailing: (lead.technician != null &&
                            lead.technician!.isNotEmpty &&
                            lead.technician!.toLowerCase() != 'unassigned')
                        ? InkWell(
                            onTap: () => TeamChatModal.show(
                              context,
                              username: lead.technician,
                              name: lead.technician,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text('Chat', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (lead.contacted != null && lead.contacted!.isNotEmpty)
                    _buildDetailRow('First Contacted', DateFormatter.formatRelative(lead.contacted!)),
                  if (lead.follow != null && lead.follow!.isNotEmpty)
                    _buildDetailRow('Next Follow-Up', DateFormatter.formatAppt(lead.follow!)),
                  const Divider(height: 20),

                  // Customer Self-Booking Links
                  const Text(
                    'Customer Self-Booking Links',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final links = await leadsProv.fetchBookingLinks(lead.id);
                            final url = links?['inspectionUrl']?.toString();
                            if (url != null && url.isNotEmpty) {
                              await Clipboard.setData(ClipboardData(text: url));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied Inspection Booking Link to clipboard!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No inspection booking link available'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: const Text('Inspection Link'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final links = await leadsProv.fetchBookingLinks(lead.id);
                            final url = links?['jobUrl']?.toString();
                            if (url != null && url.isNotEmpty) {
                              await Clipboard.setData(ClipboardData(text: url));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied Job Booking Link to clipboard!'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No job booking link available'),
                                  backgroundColor: AppColors.warning,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: const Text('Job Booking Link'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 6. Quote & Scope of Work
            _buildSectionCard(
              title: 'Quote & Invoicing Details',
              icon: Icons.receipt_long_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quote Total', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            DateFormatter.formatCurrency(lead.quoteAmount),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ],
                      ),
                      if (lead.quoteNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.cardAlt,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lead.quoteNumber!,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quote Builder & Dispatch Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => EditQuoteModal.show(context, lead),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: Text(hasQuoteItems ? 'Edit / Build Quote' : '+ Create Quote Items'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          if (lead.email == null || lead.email!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No email address saved for this customer.'),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                            return;
                          }
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Send Official Quote PDF'),
                              content: Text('Email official Groutix quotation PDF to ${lead.email}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send Email')),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            final success = await leadsProv.sendQuote(lead.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Official Quote PDF emailed to ${lead.email}!'
                                        : 'Failed to send quote.',
                                  ),
                                  backgroundColor: success ? AppColors.success : AppColors.danger,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Email PDF'),
                      ),
                    ],
                  ),
                  if (lead.quoteAcceptedAt != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.successBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quote Accepted ${lead.quoteSignedName != null ? "by ${lead.quoteSignedName}" : ""}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (lead.quoteScope != null && lead.quoteScope!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Scope of Work:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(lead.quoteScope!, style: const TextStyle(fontSize: 13, height: 1.35)),
                  ],
                  if (hasQuoteItems) ...[
                    const SizedBox(height: 12),
                    const Text('Quote Line Items:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    ...lead.quoteItems.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cardAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.service ?? item.description ?? 'Service Item',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                  if (item.scope != null && item.scope!.isNotEmpty)
                                    Text(item.scope!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(
                              '${item.qty}x ${DateFormatter.formatCurrency(item.price)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const Divider(height: 20),

                  // Financial Status & Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invoice Status', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            lead.invoiceStatus ?? 'Not Invoiced',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: lead.invoiceStatus == 'Paid' ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: lead.warrantyProvided == true ? AppColors.successBg : AppColors.cardAlt,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: lead.warrantyProvided == true ? AppColors.successBorder : AppColors.border,
                          ),
                        ),
                        child: Text(
                          lead.warrantyProvided == true ? '🛡️ 10-Yr Warranty Issued' : 'Warranty Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: lead.warrantyProvided == true ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Financial Buttons Bar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => SendInvoiceSheet.show(context, lead),
                          child: const Text('Send Invoice'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => RecordPaymentDialog.show(context, lead),
                          child: const Text('Payment'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => IssueWarrantySheet.show(context, lead),
                          child: const Text('Warranty'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 7. Inspection Report (if present)
            if (lead.inspectionReport != null) ...[
              _buildSectionCard(
                title: 'Inspection Visit Findings',
                icon: Icons.checklist_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Report Status', lead.inspectionReport!.status.toUpperCase()),
                    if (lead.inspectionReport!.room != null)
                      _buildDetailRow('Room Inspected', lead.inspectionReport!.room!),
                    if (lead.inspectionReport!.warrantyEligible != null)
                      _buildDetailRow('Warranty Eligible', lead.inspectionReport!.warrantyEligible!),
                    if (lead.inspectionReport!.estimatedTime != null)
                      _buildDetailRow('Estimated Time', lead.inspectionReport!.estimatedTime!),
                    _buildDetailRow(
                      'Checklist Summary',
                      '${lead.inspectionReport!.summary.yesCount} Issues Flagged / ${lead.inspectionReport!.summary.totalItems} Items Checked',
                    ),
                    if (lead.inspectionReport!.inspectorNotes != null && lead.inspectionReport!.inspectorNotes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Text('Inspector Notes:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(lead.inspectionReport!.inspectorNotes!, style: const TextStyle(fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 8. Work Photos Section
            _buildSectionCard(
              title: 'Photos & Evidence (${lead.photos.length})',
              icon: Icons.photo_library_rounded,
              trailing: TextButton.icon(
                onPressed: _handleUploadPhotos,
                icon: const Icon(Icons.add_a_photo_rounded, size: 15),
                label: const Text('Add Photo'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lead.photos.isEmpty)
                    const Text('No photos uploaded yet.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: lead.photos.length,
                      itemBuilder: (ctx, i) {
                        final p = lead.photos[i];
                        return InkWell(
                          onTap: () => PhotoViewerModal.show(
                            context,
                            p,
                            onDelete: () {
                              if (p.publicId != null) {
                                leadsProv.deletePhoto(lead.id, p.publicId!);
                              }
                            },
                          ),
                          borderRadius: BorderRadius.circular(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              p.displayUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.cardAlt,
                                child: const Icon(Icons.broken_image_rounded, size: 24, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 9. Activity & Audit Trail
            if (lead.activity.isNotEmpty)
              _buildSectionCard(
                title: 'Activity Log (${lead.activity.length})',
                icon: Icons.history_rounded,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lead.activity.take(10).length,
                  separatorBuilder: (context, index) => const Divider(height: 14),
                  itemBuilder: (ctx, i) {
                    final act = lead.activity[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(act.action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            Text(DateFormatter.formatRelative(act.time), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'By ${act.actor}${act.detail != null ? " • ${act.detail}" : ""}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
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
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_calendar_rounded, size: 16),
          tooltip: 'Reschedule',
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
          ),
        ),
      ],
    );
  }

  Widget _buildCallChip(String label, IconData icon, Color color) {
    return ActionChip(
      avatar: Icon(icon, size: 13, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () => _handleLogCall(label),
    );
  }
}
