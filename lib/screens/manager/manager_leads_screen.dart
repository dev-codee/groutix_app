import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/leads_provider.dart';
import '../common/empty_state.dart';
import '../common/lead_card.dart';
import 'create_lead_modal.dart';
import 'manager_lead_detail_screen.dart';

class ManagerLeadsScreen extends StatefulWidget {
  const ManagerLeadsScreen({super.key});

  @override
  State<ManagerLeadsScreen> createState() => _ManagerLeadsScreenState();
}

class _ManagerLeadsScreenState extends State<ManagerLeadsScreen> {
  final _searchController = TextEditingController();

  final List<String> _filterCategories = [
    'All',
    'New',
    'Inspection Booked',
    'Quote Pending',
    'Won',
    'Job In Progress',
    'Job Done',
    'Completed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsProv = context.watch<LeadsProvider>();
    final scopedLeads = leadsProv.getScopedLeads(UserRole.manager);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipeline & Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => leadsProv.fetchLeads(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Job #, client, address, phone...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              leadsProv.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                  onChanged: (val) => leadsProv.setSearchQuery(val),
                ),
                const SizedBox(height: 10),

                // Horizontal stage filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterCategories.map((cat) {
                      final isSelected = (cat == 'All' && leadsProv.selectedStatusFilter == null) ||
                          (leadsProv.selectedStatusFilter == cat);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            leadsProv.setStatusFilter(cat == 'All' ? null : cat);
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.cardAlt,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Leads List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => leadsProv.fetchLeads(),
              child: leadsProv.isLoading && scopedLeads.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : leadsProv.errorMessage != null && scopedLeads.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
                                const SizedBox(height: 12),
                                Text(
                                  leadsProv.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => leadsProv.fetchLeads(),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                ),
                              ],
                            ),
                          ),
                        )
                      : scopedLeads.isEmpty
                          ? const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No leads found',
                              message: 'Try adjusting your search criteria or status filter.',
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: scopedLeads.length,
                              itemBuilder: (ctx, i) {
                                final lead = scopedLeads[i];
                                return LeadCard(
                                  lead: lead,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ManagerLeadDetailScreen(leadId: lead.id),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateLeadModal.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Lead'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
