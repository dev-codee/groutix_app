import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/inspection_report.dart';
import '../../models/lead_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inspection_provider.dart';

class InspectionFormScreen extends StatefulWidget {
  final LeadModel lead;

  const InspectionFormScreen({super.key, required this.lead});

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _notesController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _signatureController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final insp = context.read<InspectionProvider>();
      insp.initForLead(widget.lead, inspectorUsername: auth.currentUser?.displayName);
      _notesController.text = insp.currentReport.inspectorNotes ?? '';
      _estimatedTimeController.text = insp.currentReport.estimatedTime ?? '';
      _signatureController.text = insp.currentReport.inspectorSignature ?? auth.currentUser?.displayName ?? '';
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _estimatedTimeController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _handleSave({bool markCompleted = false}) async {
    final insp = context.read<InspectionProvider>();
    insp.updateField(
      inspectorNotes: _notesController.text.trim(),
      estimatedTime: _estimatedTimeController.text.trim(),
      inspectorSignature: _signatureController.text.trim(),
    );

    final success = await insp.saveReport(markCompleted: markCompleted);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(markCompleted ? 'Inspection completed and saved!' : 'Draft report saved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      if (markCompleted) Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(insp.errorMessage ?? 'Failed to save inspection report.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final insp = context.watch<InspectionProvider>();
    final report = insp.currentReport;
    final summary = report.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Inspection Report'),
        actions: [
          TextButton.icon(
            onPressed: insp.isSaving ? null : () => _handleSave(markCompleted: false),
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save Draft'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Summary Pill Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryBadge('YES', summary.yesCount, AppColors.successBg, AppColors.success),
                _buildSummaryBadge('NO', summary.noCount, AppColors.dangerBg, AppColors.danger),
                _buildSummaryBadge('Pending', summary.unansweredCount, AppColors.cardAlt, AppColors.textSecondary),
                _buildSummaryBadge('Total', summary.totalItems, AppColors.infoBg, AppColors.info),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Scrollable Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Details
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
                      Text(
                        'Client: ${widget.lead.displayName}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Address: ${widget.lead.fullAddress}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inspector: ${report.inspectorName ?? "Field Specialist"}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 8 Inspection Checklist Sections
                ...kInspectionSections.map((section) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(
                          section.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                        children: [
                          const Divider(height: 1, color: AppColors.border),
                          ...section.items.map((item) {
                            final currentVal = report.findings[item.id] ?? '';

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // YES Pill
                                  _buildChoiceButton(
                                    label: 'YES',
                                    isSelected: currentVal == 'YES',
                                    color: AppColors.success,
                                    onTap: () => insp.setFinding(item.id, 'YES'),
                                  ),
                                  const SizedBox(width: 6),
                                  // NO Pill
                                  _buildChoiceButton(
                                    label: 'NO',
                                    isSelected: currentVal == 'NO',
                                    color: AppColors.danger,
                                    onTap: () => insp.setFinding(item.id, 'NO'),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),

                // Extra Fields & Notes
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
                        'Additional Field Details',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _estimatedTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Job Duration (e.g. 1 Day, 2 Days)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Inspector Observations / Notes',
                          hintText: 'Enter specific grout, tile or leak findings...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _signatureController,
                        decoration: const InputDecoration(
                          labelText: 'Inspector Digital Signature (Full Name)',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save & Complete Button
                ElevatedButton.icon(
                  onPressed: insp.isSaving ? null : () => _handleSave(markCompleted: true),
                  icon: insp.isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'Complete & Submit Report',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge(String label, int count, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
