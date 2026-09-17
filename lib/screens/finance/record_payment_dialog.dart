import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/lead_model.dart';
import '../../providers/finance_provider.dart';
import '../../providers/leads_provider.dart';

class RecordPaymentDialog extends StatefulWidget {
  final LeadModel lead;

  const RecordPaymentDialog({super.key, required this.lead});

  static void show(BuildContext context, LeadModel lead) {
    showDialog(
      context: context,
      builder: (ctx) => RecordPaymentDialog(lead: lead),
    );
  }

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  String _paymentType = 'full';
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = (widget.lead.quoteAmount ?? 0.0).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _handleRecord() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount.')),
      );
      return;
    }

    final finance = context.read<FinanceProvider>();
    final leadsProv = context.read<LeadsProvider>();

    final success = await finance.recordPayment(
      leadId: widget.lead.id,
      type: _paymentType,
      amount: amount,
    );

    if (!mounted) return;

    if (success) {
      await leadsProv.updateLeadField(widget.lead.id, {
        'status': 'Payment Received',
        'amountPaid': amount,
        'paymentType': _paymentType,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment recorded! Lead is now ready for warranty issuance.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quoteTotal = widget.lead.quoteAmount ?? 0.0;

    return AlertDialog(
      title: const Text('Record Customer Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client: ${widget.lead.displayName}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            'Quote Total: ${DateFormatter.formatCurrency(quoteTotal)}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Payment Type Switcher
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Full Payment'),
                  selected: _paymentType == 'full',
                  onSelected: (_) {
                    setState(() {
                      _paymentType = 'full';
                      _amountController.text = quoteTotal.toStringAsFixed(2);
                    });
                  },
                  selectedColor: AppColors.success,
                  labelStyle: TextStyle(
                    color: _paymentType == 'full' ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Partial Deposit'),
                  selected: _paymentType == 'partial',
                  onSelected: (_) {
                    setState(() {
                      _paymentType = 'partial';
                      _amountController.text = (quoteTotal / 2).toStringAsFixed(2);
                    });
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _paymentType == 'partial' ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Received Amount (AUD)',
              prefixText: '\$ ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleRecord,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: const Text('Confirm Payment'),
        ),
      ],
    );
  }
}
