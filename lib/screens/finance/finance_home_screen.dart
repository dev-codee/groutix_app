import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/lead_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leads_provider.dart';
import '../common/empty_state.dart';
import '../common/lead_card.dart';
import 'issue_warranty_sheet.dart';
import 'record_payment_dialog.dart';
import 'send_invoice_sheet.dart';

class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key});

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeadsProvider>().fetchLeads();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leadsProv = context.watch<LeadsProvider>();
    final financeLeads = leadsProv.getScopedLeads(UserRole.finance);

    final needsInvoice = financeLeads.where((l) => l.status == 'Job Done').toList();
    final paymentPending = financeLeads.where((l) => ['Invoice Sent', 'Payment Pending'].contains(l.status)).toList();
    final paymentReceived = financeLeads.where((l) => l.status == 'Payment Received').toList();
    final completed = financeLeads.where((l) => ['Warranty Sent', 'Completed'].contains(l.status)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${auth.currentUser?.displayName ?? "Finance"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const Text(
              'Invoicing & Payment Flow',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => leadsProv.fetchLeads(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Needs Invoice (${needsInvoice.length})'),
            Tab(text: 'Pending Payment (${paymentPending.length})'),
            Tab(text: 'Payment Received (${paymentReceived.length})'),
            Tab(text: 'Completed (${completed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Needs Invoice
          _buildLeadList(
            leads: needsInvoice,
            emptyTitle: 'No Invoices Pending',
            emptyMessage: 'All completed jobs have been invoiced.',
            actionBuilder: (lead) => ElevatedButton.icon(
              onPressed: () => SendInvoiceSheet.show(context, lead),
              icon: const Icon(Icons.receipt_long_rounded, size: 15),
              label: const Text('Send Invoice'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),

          // 2. Pending Payment
          _buildLeadList(
            leads: paymentPending,
            emptyTitle: 'No Pending Payments',
            emptyMessage: 'No outstanding customer payments in this stage.',
            actionBuilder: (lead) => ElevatedButton.icon(
              onPressed: () => RecordPaymentDialog.show(context, lead),
              icon: const Icon(Icons.attach_money_rounded, size: 16),
              label: const Text('Record Payment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),

          // 3. Payment Received
          _buildLeadList(
            leads: paymentReceived,
            emptyTitle: 'No Warranties Awaiting',
            emptyMessage: 'All received payments have warranties issued.',
            actionBuilder: (lead) => ElevatedButton.icon(
              onPressed: () => IssueWarrantySheet.show(context, lead),
              icon: const Icon(Icons.verified_rounded, size: 15),
              label: const Text('Issue Warranty'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),

          // 4. Completed
          _buildLeadList(
            leads: completed,
            emptyTitle: 'No Completed Jobs Yet',
            emptyMessage: 'Finished and warrantied jobs will appear here.',
            actionBuilder: (lead) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Closed 🏆',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadList({
    required List<LeadModel> leads,
    required String emptyTitle,
    required String emptyMessage,
    required Widget Function(LeadModel) actionBuilder,
  }) {
    if (leads.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leads.length,
      itemBuilder: (ctx, i) {
        final lead = leads[i];
        return LeadCard(
          lead: lead,
          onTap: () {},
          trailingAction: actionBuilder(lead),
        );
      },
    );
  }
}
