import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/lead_model.dart';
import '../../providers/finance_provider.dart';
import '../../providers/leads_provider.dart';

class SendInvoiceSheet extends StatefulWidget {
  final LeadModel lead;

  const SendInvoiceSheet({super.key, required this.lead});

  static void show(BuildContext context, LeadModel lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SendInvoiceSheet(lead: lead),
    );
  }

  @override
  State<SendInvoiceSheet> createState() => _SendInvoiceSheetState();
}

class _SendInvoiceSheetState extends State<SendInvoiceSheet> {
  final _priceController = TextEditingController();
  final _serviceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bankNameController = TextEditingController(text: 'NAB');
  final _accountNameController = TextEditingController(text: 'Groutix Pty Ltd');
  final _bsbController = TextEditingController(text: '083-004');
  final _accountNumberController = TextEditingController(text: '728194021');

  final double _gstRate = 10.0;

  @override
  void initState() {
    super.initState();
    _priceController.text = (widget.lead.quoteAmount ?? 0.0).toStringAsFixed(2);
    _serviceController.text = widget.lead.service ?? 'Shower & Grout Restoration';
    _descriptionController.text = widget.lead.quoteScope ?? 'Complete professional regrouting and sealing as inspected.';
  }

  @override
  void dispose() {
    _priceController.dispose();
    _serviceController.dispose();
    _descriptionController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _bsbController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  void _handleSendInvoice() async {
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid invoice price.')),
      );
      return;
    }

    final finance = context.read<FinanceProvider>();
    final leadsProv = context.read<LeadsProvider>();

    final success = await finance.sendInvoice(
      leadId: widget.lead.id,
      price: price,
      gst: _gstRate,
      service: _serviceController.text.trim(),
      description: _descriptionController.text.trim(),
      bankName: _bankNameController.text.trim(),
      accountName: _accountNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      bsb: _bsbController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      await leadsProv.updateLeadField(widget.lead.id, {'status': 'Invoice Sent'});
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice PDF generated and emailed to customer!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(finance.errorMessage ?? 'Failed to send invoice.'),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Issue & Email Invoice',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Client: ${widget.lead.displayName} (${widget.lead.displayJobNo})',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Price & GST
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total Price (AUD Incl. GST)',
                      prefixText: '\$ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      '10% GST',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Service Title
            TextField(
              controller: _serviceController,
              decoration: const InputDecoration(
                labelText: 'Service Summary',
              ),
            ),
            const SizedBox(height: 14),

            // Description Scope
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Invoice Line Item Description',
              ),
            ),
            const SizedBox(height: 16),

            // Bank Payment Details
            const Text(
              'Bank Deposit Details for PDF',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bsbController,
                    decoration: const InputDecoration(labelText: 'BSB'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _accountNumberController,
                    decoration: const InputDecoration(labelText: 'Account #'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Send Button
            ElevatedButton.icon(
              onPressed: finance.isProcessing ? null : _handleSendInvoice,
              icon: finance.isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Generate & Email Invoice',
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
