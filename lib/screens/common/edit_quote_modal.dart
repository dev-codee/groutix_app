import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/lead_model.dart';
import '../../models/quote_item.dart';
import '../../providers/leads_provider.dart';

class EditQuoteModal extends StatefulWidget {
  final LeadModel lead;

  const EditQuoteModal({super.key, required this.lead});

  static void show(BuildContext context, LeadModel lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditQuoteModal(lead: lead),
    );
  }

  @override
  State<EditQuoteModal> createState() => _EditQuoteModalState();
}

class _EditQuoteModalState extends State<EditQuoteModal> {
  late List<QuoteItem> _items;
  final _scopeController = TextEditingController();
  bool _isSaving = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _items = widget.lead.quoteItems.isNotEmpty
        ? List.from(widget.lead.quoteItems)
        : [
            QuoteItem(
              service: widget.lead.service ?? 'Shower Regrouting & Sealing',
              description: 'Standard Groutix restoration and epoxy perimeter seal.',
              price: widget.lead.quoteAmount ?? 450.0,
              qty: 1,
            )
          ];
    _scopeController.text = widget.lead.quoteScope ?? '';
  }

  @override
  void dispose() {
    _scopeController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, i) => sum + i.total);
  }

  double get _gst => _subtotal * 0.10;
  double get _grandTotal => _subtotal + _gst;

  void _addNewItem() {
    setState(() {
      _items.add(
        QuoteItem(
          service: 'Additional Service Item',
          description: '',
          price: 150.0,
          qty: 1,
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _handleSaveQuote() async {
    setState(() => _isSaving = true);
    final leadsProv = context.read<LeadsProvider>();

    final success = await leadsProv.updateLeadField(widget.lead.id, {
      'quoteItems': _items.map((i) => i.toJson()).toList(),
      'quoteAmount': _grandTotal,
      'quoteScope': _scopeController.text.trim(),
    });

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote saved successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save quote changes.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleSendOfficialQuote() async {
    // Save quote first if items modified
    setState(() => _isSending = true);
    final leadsProv = context.read<LeadsProvider>();

    await leadsProv.updateLeadField(widget.lead.id, {
      'quoteItems': _items.map((i) => i.toJson()).toList(),
      'quoteAmount': _grandTotal,
      'quoteScope': _scopeController.text.trim(),
    });

    final success = await leadsProv.sendQuote(widget.lead.id);
    setState(() => _isSending = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Official Quote PDF emailed to customer!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not email quote. Ensure customer has an email address.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _editItemDialog(int index) {
    final item = _items[index];
    final serviceCtrl = TextEditingController(text: item.service ?? '');
    final descCtrl = TextEditingController(text: item.description ?? item.scope ?? '');
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(2));
    final qtyCtrl = TextEditingController(text: item.qty.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Line Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: serviceCtrl,
                decoration: const InputDecoration(labelText: 'Service Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Scope / Description'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Unit Price (\$AUD)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(priceCtrl.text) ?? item.price;
              final newQty = int.tryParse(qtyCtrl.text) ?? item.qty;
              setState(() {
                _items[index] = QuoteItem(
                  service: serviceCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  price: newPrice,
                  qty: newQty,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quote Builder — ${widget.lead.displayName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${widget.lead.displayJobNo} • ${widget.lead.email ?? "No email"}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line Items List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quote Line Items',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      TextButton.icon(
                        onPressed: _addNewItem,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Line Items Cards
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('No items added. Tap "Add Item" to begin.'),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _editItemDialog(i),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.service ?? 'Service Item',
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          DateFormatter.formatCurrency(item.total),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                    if (item.description != null && item.description!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.description!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.qty}x @ ${DateFormatter.formatCurrency(item.price)} each • Tap to edit',
                                      style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                              onPressed: () => _removeItem(i),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 14),

                  // Scope of Work Narrative
                  const Text(
                    'Overall Scope of Work Narrative',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _scopeController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter complete scope description to appear on customer quote PDF...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Totals Summary Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal (excl. GST):', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text(DateFormatter.formatCurrency(_subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GST (10%):', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text(DateFormatter.formatCurrency(_gst), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Quote Value (AUD):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            Text(
                              DateFormatter.formatCurrency(_grandTotal),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _handleSaveQuote,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    child: Text(_isSaving ? 'Saving...' : 'Save Quote'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _handleSendOfficialQuote,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(_isSending ? 'Sending...' : 'Email Quote PDF'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
