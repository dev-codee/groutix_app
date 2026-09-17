import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/launcher_helper.dart';
import '../../providers/leads_provider.dart';
import 'status_pill.dart';

class LeadChatModal extends StatefulWidget {
  final String leadId;
  final String initialChannel; // 'email' or 'sms'

  const LeadChatModal({
    super.key,
    required this.leadId,
    this.initialChannel = 'email',
  });

  static void show(BuildContext context, String leadId, {String initialChannel = 'email'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LeadChatModal(
        leadId: leadId,
        initialChannel: initialChannel,
      ),
    );
  }

  @override
  State<LeadChatModal> createState() => _LeadChatModalState();
}

class _LeadChatModalState extends State<LeadChatModal> {
  late String _currentChannel;
  final _messageController = TextEditingController();
  final _subjectController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.initialChannel;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leadsProv = context.read<LeadsProvider>();
      final lead = leadsProv.getLeadById(widget.leadId);
      if (lead != null) {
        final firstName = lead.name?.trim().split(RegExp(r'\s+')).first ?? 'there';
        _subjectController.text = 'Re: Groutix Service — ${lead.displayName}';
        if (_currentChannel == 'sms') {
          _messageController.text = 'Hi $firstName, regarding your Groutix service: ';
        }
      }
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _subjectController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _applyTemplate(String text) {
    setState(() {
      _messageController.text = text;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final leadsProv = context.read<LeadsProvider>();
    bool ok = false;

    if (_currentChannel == 'email') {
      final subject = _subjectController.text.trim().isNotEmpty
          ? _subjectController.text.trim()
          : 'Re: Groutix Enquiry';
      ok = await leadsProv.sendLeadEmail(widget.leadId, subject: subject, text: text);
    } else {
      ok = await leadsProv.sendLeadSms(widget.leadId, text: text);
    }

    setState(() => _isSending = false);

    if (!mounted) return;

    if (ok) {
      _messageController.clear();
      _scrollToBottom();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_currentChannel == 'email' ? 'Email sent to customer' : 'SMS sent to customer'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send ${_currentChannel.toUpperCase()}. Please check your connection.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leadsProv = context.watch<LeadsProvider>();
    final lead = leadsProv.getLeadById(widget.leadId);

    if (lead == null) {
      return Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(child: Text('Lead not found')),
      );
    }

    final firstName = lead.name?.trim().split(RegExp(r'\s+')).first ?? 'Customer';

    // Build synthesized conversation list
    final messages = <Map<String, dynamic>>[];

    // If initial customer request exists, put it first
    if (lead.notes != null && lead.notes!.isNotEmpty) {
      messages.add({
        'from': 'customer',
        'channel': 'lead',
        'text': 'Initial Request / Notes: ${lead.notes}',
        'time': lead.createdAt ?? '',
      });
    } else if (lead.message != null && lead.message!.isNotEmpty) {
      messages.add({
        'from': 'customer',
        'channel': 'lead',
        'text': lead.message!,
        'time': lead.createdAt ?? '',
      });
    }

    // Add stored messages
    for (final m in lead.messages) {
      messages.add({
        'from': m.from,
        'channel': m.channel ?? 'email',
        'text': m.text,
        'time': m.time,
      });
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              lead.displayName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(status: lead.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lead.displayJobNo} • ${lead.phone ?? lead.email ?? "Direct Chat"}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // External App Fallback
                if (lead.phone != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
                    tooltip: 'External WhatsApp / SMS',
                    onPressed: () => LauncherHelper.showMessageOptions(context, lead.phone, name: lead.displayName),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Channel Switcher (Email vs SMS)
          Container(
            color: AppColors.cardAlt,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Channel:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      ChoiceChip(
                        avatar: Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: _currentChannel == 'email' ? Colors.white : AppColors.primary,
                        ),
                        label: const Text('Email'),
                        selected: _currentChannel == 'email',
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _currentChannel == 'email' ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _currentChannel = 'email';
                              if (_messageController.text.startsWith('Hi $firstName, regarding your Groutix service: ')) {
                                _messageController.clear();
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: Icon(
                          Icons.sms_outlined,
                          size: 14,
                          color: _currentChannel == 'sms' ? Colors.white : Colors.green.shade700,
                        ),
                        label: const Text('SMS Text'),
                        selected: _currentChannel == 'sms',
                        selectedColor: Colors.green.shade700,
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _currentChannel == 'sms' ? Colors.white : AppColors.textPrimary,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _currentChannel = 'sms';
                              if (_messageController.text.isEmpty) {
                                _messageController.text = 'Hi $firstName, regarding your Groutix service: ';
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages Thread
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text('No messages yet with $firstName.', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        const Text('Send an email or SMS below.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = messages[i];
                      final isMe = msg['from'] == 'groutix' || msg['from'] == 'staff';
                      final channel = msg['channel']?.toString() ?? 'email';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.primary : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(2),
                              bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(14),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Sender & Channel Badge
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isMe ? 'Groutix Staff' : lead.displayName,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: isMe ? Colors.white70 : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.white24 : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      channel.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: isMe ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Message Text
                              Text(
                                msg['text']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isMe ? Colors.white : AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                              if (msg['time'] != null && msg['time'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  DateFormatter.formatRelative(msg['time'].toString()),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: isMe ? Colors.white60 : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Quick Templates Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildQuickTemplateChip('Inspection Reminder', 'Hi $firstName, this is a quick reminder about your scheduled Groutix inspection visit.'),
                const SizedBox(width: 6),
                _buildQuickTemplateChip('Quote Ready', 'Hi $firstName, your Groutix service quote is now ready for your review. Please let us know if you have any questions!'),
                const SizedBox(width: 6),
                _buildQuickTemplateChip('Technician ETA', 'Hi $firstName, our technician is en route to your property now.'),
              ],
            ),
          ),

          // Composer Input Bar (Keyboard avoided)
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // If Email: Subject line input
                if (_currentChannel == 'email')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TextField(
                      controller: _subjectController,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Subject',
                        labelStyle: TextStyle(fontSize: 11.5),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),

                // Main Message Input + Send Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: _currentChannel == 'email'
                              ? 'Write email to ${lead.displayName}...'
                              : 'Write SMS to ${lead.displayName}...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSending ? null : _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: _currentChannel == 'email' ? AppColors.primary : Colors.green.shade700,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplateChip(String label, String templateText) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.cardAlt,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _applyTemplate(templateText),
    );
  }
}
