import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/leads_provider.dart';
import 'manager_lead_detail_screen.dart';

class CreateLeadModal extends StatefulWidget {
  const CreateLeadModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CreateLeadModal(),
    );
  }

  @override
  State<CreateLeadModal> createState() => _CreateLeadModalState();
}

class _CreateLeadModalState extends State<CreateLeadModal> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _serviceController = TextEditingController();
  final _areasController = TextEditingController();
  final _damagedTilesController = TextEditingController();
  final _agencyController = TextEditingController();
  final _notesController = TextEditingController();

  String _status = 'New';
  String _customerType = 'Homeowner';
  String _leaking = 'No';
  bool _isSaving = false;

  final List<String> _stages = [
    'New',
    'Contacted',
    'Inspection Booked',
    'Quote Pending',
    'Won',
    'Job Booked',
  ];

  final List<String> _customerTypes = [
    'Homeowner',
    'Real Estate Agency',
    'Strata',
    'Commercial',
    'Tenant',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _serviceController.dispose();
    _areasController.dispose();
    _damagedTilesController.dispose();
    _agencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final leadsProv = context.read<LeadsProvider>();

    final payload = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'service': _serviceController.text.trim(),
      'areas': _areasController.text.trim(),
      'damagedTiles': _damagedTilesController.text.trim(),
      'leaking': _leaking,
      'customerType': _customerType,
      if (_customerType == 'Real Estate Agency' && _agencyController.text.trim().isNotEmpty)
        'agency': _agencyController.text.trim(),
      'notes': _notesController.text.trim(),
      'status': _status,
      'source': 'Mobile App Entry',
    };

    final created = await leadsProv.createLead(payload);
    setState(() => _isSaving = false);

    if (!mounted) return;

    if (created != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lead created: ${created.displayName} (${created.displayJobNo})'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManagerLeadDetailScreen(leadId: created.id),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create lead. Please check network/server.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
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
                const Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Add New Customer Lead',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
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

          // Form fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Name
                    const Text('Customer Name *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. John Doe',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter customer name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Phone & Email Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Phone Number', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: '0412 345 678',
                                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Email Address', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'john@example.com',
                                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Property Address
                    const Text('Property Address', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'Street address, suburb, VIC',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Service Required
                    const Text('Service / Task Required', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _serviceController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Shower Regrouting, Epoxy, Balcony Seal',
                        prefixIcon: Icon(Icons.build_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Areas / Rooms
                    const Text('Specific Areas / Rooms', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _areasController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Master Ensuite, Main Bathroom, Kitchen',
                        prefixIcon: Icon(Icons.meeting_room_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Damaged Tiles & Leaking Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Damaged Tiles', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _damagedTilesController,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Yes, 2 cracked',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Leakage', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _leaking,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: ['No', 'Yes', 'Suspected'].map((v) {
                                  return DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _leaking = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Customer Type & Initial Stage Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Customer Type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _customerType,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: _customerTypes.map((v) {
                                  return DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _customerType = v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Initial Stage', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _status,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                items: _stages.map((v) {
                                  return DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 12)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _status = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_customerType == 'Real Estate Agency') ...[
                      const SizedBox(height: 14),
                      const Text('Agency Name', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _agencyController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Ray White, Barry Plant',
                          prefixIcon: Icon(Icons.business_outlined, size: 18),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Notes / Details
                    const Text('Notes & Customer Request Details', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Enter any customer remarks, observations or special requests...',
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
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
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_isSaving ? 'Creating Lead...' : 'Create Lead & Open'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
