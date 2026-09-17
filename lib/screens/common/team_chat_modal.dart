import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/team_message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leads_provider.dart';

class TeamChatModal extends StatefulWidget {
  final StaffMemberModel? initialStaff;
  final String? initialUsername;
  final String? initialName;

  const TeamChatModal({
    super.key,
    this.initialStaff,
    this.initialUsername,
    this.initialName,
  });

  static Future<void> show(
    BuildContext context, {
    StaffMemberModel? staff,
    String? username,
    String? name,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TeamChatModal(
        initialStaff: staff,
        initialUsername: username,
        initialName: name,
      ),
    );
  }

  @override
  State<TeamChatModal> createState() => _TeamChatModalState();
}

class _TeamChatModalState extends State<TeamChatModal> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  StaffMemberModel? _selectedStaff;
  List<TeamMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    final leadsProv = context.read<LeadsProvider>();
    final staffList = await leadsProv.fetchStaff();

    if (widget.initialStaff != null) {
      _selectedStaff = widget.initialStaff;
    } else if (widget.initialUsername != null && widget.initialUsername!.isNotEmpty) {
      final match = staffList.firstWhere(
        (s) => s.username.toLowerCase() == widget.initialUsername!.toLowerCase(),
        orElse: () => StaffMemberModel(
          id: widget.initialUsername!,
          username: widget.initialUsername!,
          name: widget.initialName ?? widget.initialUsername!,
          role: 'Staff',
        ),
      );
      _selectedStaff = match;
    }

    if (_selectedStaff != null) {
      await _loadConversation();
      _startPolling();
    } else if (mounted) {
      setState(() {});
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_selectedStaff != null && mounted) {
        _refreshMessages();
      }
    });
  }

  Future<void> _loadConversation() async {
    if (_selectedStaff == null) return;
    setState(() => _isLoading = true);
    final leadsProv = context.read<LeadsProvider>();
    final msgs = await leadsProv.fetchTeamMessages(_selectedStaff!.username);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _refreshMessages() async {
    if (_selectedStaff == null) return;
    final leadsProv = context.read<LeadsProvider>();
    final msgs = await leadsProv.fetchTeamMessages(_selectedStaff!.username);
    if (mounted && msgs.length != _messages.length) {
      setState(() => _messages = msgs);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _selectedStaff == null || _isSending) return;

    setState(() => _isSending = true);
    final leadsProv = context.read<LeadsProvider>();
    final sent = await leadsProv.sendTeamMessage(_selectedStaff!.username, text);

    if (mounted) {
      setState(() => _isSending = false);
      if (sent != null) {
        _textController.clear();
        setState(() {
          _messages.add(sent);
        });
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send team message'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final leadsProv = context.watch<LeadsProvider>();
    final currentUsername = auth.currentUser?.username.toLowerCase() ?? '';
    final staffList = leadsProv.staff.where((s) => s.username.toLowerCase() != currentUsername).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_selectedStaff != null && widget.initialStaff == null && widget.initialUsername == null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    onPressed: () {
                      _pollingTimer?.cancel();
                      setState(() {
                        _selectedStaff = null;
                        _messages = [];
                      });
                    },
                  ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    _selectedStaff != null
                        ? (_selectedStaff!.name.isNotEmpty ? _selectedStaff!.name[0].toUpperCase() : 'T')
                        : '👥',
                    style: TextStyle(
                      fontSize: _selectedStaff != null ? 16 : 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedStaff != null ? _selectedStaff!.name : 'Internal Team Chat',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _selectedStaff != null
                            ? '${_selectedStaff!.roleDisplay} • @${_selectedStaff!.username}'
                            : 'Direct staff messaging & coordination',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body: Either Staff Picker Directory or Conversation View
          Expanded(
            child: _selectedStaff == null
                ? _buildStaffPicker(staffList, leadsProv)
                : _buildConversation(currentUsername),
          ),

          // Bottom Input Field (only when chat target is selected)
          if (_selectedStaff != null) ...[
            const Divider(height: 1),
            Container(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              color: AppColors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Message ${_selectedStaff!.name.split(" ").first}…',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.cardAlt,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _handleSend,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffPicker(List<StaffMemberModel> staffList, LeadsProvider leadsProv) {
    if (staffList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded, size: 40, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No staff members found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: staffList.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
      itemBuilder: (ctx, i) {
        final staff = staffList[i];
        final unread = leadsProv.teamUnread[staff.username.toLowerCase()] ?? 0;

        return ListTile(
          onTap: () {
            setState(() {
              _selectedStaff = staff;
            });
            _loadConversation();
            _startPolling();
          },
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unread',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Text(
            '${staff.roleDisplay} • @${staff.username}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
        );
      },
    );
  }

  Widget _buildConversation(String currentUsername) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2.5),
            SizedBox(height: 12),
            Text('Loading conversation…', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No messages yet',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Say hello to ${_selectedStaff?.name.split(" ").first ?? "your teammate"}.',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        final msg = _messages[i];
        final isMe = msg.from.toLowerCase() == currentUsername;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.cardAlt,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: isMe ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatRelative(msg.createdAt.toIso8601String()),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
