import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/lead_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/leads_provider.dart';

class IssueWarrantySheet extends StatefulWidget {
  final LeadModel lead;

  const IssueWarrantySheet({super.key, required this.lead});

  static void show(BuildContext context, LeadModel lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IssueWarrantySheet(lead: lead),
    );
  }

  @override
  State<IssueWarrantySheet> createState() => _IssueWarrantySheetState();
}

class _IssueWarrantySheetState extends State<IssueWarrantySheet> {
  final _customerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _authorisedByController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _customerNameController.text = widget.lead.displayName;
    _addressController.text = widget.lead.fullAddress;
    _authorisedByController.text = auth.currentUser?.displayName ?? 'Groutix Operations';
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _addressController.dispose();
    _authorisedByController.dispose();
    super.dispose();
  }

  void _handleIssueWarranty() async {
    final finance = context.read<FinanceProvider>();
    final leadsProv = context.read<LeadsProvider>();

    final now = DateTime.now();
    final completionDate = now.toIso8601String().substring(0, 10);
    final expiryDate = DateTime(now.year + 10, now.month, now.day).toIso8601String().substring(0, 10);

    final success = await finance.issueWarranty(
      leadId: widget.lead.id,
      customerName: _customerNameController.text.trim(),
      address: _addressController.text.trim(),
      jobNo: widget.lead.displayJobNo,
      completionDate: completionDate,
      expiryDate: expiryDate,
      authorisedBy: _authorisedByController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await leadsProv.updateLeadField(widget.lead.id, {
        'status': 'Completed',
        'warrantyProvided': true,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('10-Year Warranty Certificate generated and sent! Job marked Completed 🏆'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(finance.errorMessage ?? 'Failed to issue warranty.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Issue 10-Year Warranty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Covered Property Address'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _authorisedByController,
              decoration: const InputDecoration(labelText: 'Authorised By'),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: finance.isProcessing ? null : _handleIssueWarranty,
              icon: finance.isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Issue Warranty & Complete Job 🏆',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
