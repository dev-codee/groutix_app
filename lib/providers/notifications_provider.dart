import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/notification_service.dart';
import '../models/app_notification_model.dart';
import '../models/lead_model.dart';
import '../models/user_model.dart';

class NotificationsProvider with ChangeNotifier {
  static const String _storageKey = 'groutix_app_notifications_v1';
  static const String _knownLeadsKey = 'groutix_known_lead_ids_v1';

  final NotificationService _notificationService = NotificationService();

  List<AppNotificationModel> _notifications = [];
  final Set<String> _knownLeadIds = {};
  final Map<String, String> _knownLeadStatuses = {};
  final Map<String, int> _knownCustomerMessageCounts = {};
  final Map<String, int> _knownTeamUnread = {};
  bool _isFirstCheck = true;

  AppNotificationModel? _activeInAppBanner;
  Timer? _bannerDismissTimer;

  List<AppNotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  AppNotificationModel? get activeInAppBanner => _activeInAppBanner;

  NotificationsProvider() {
    _init();
  }

  Future<void> _init() async {
    await _notificationService.init();
    await _loadPersistedNotifications();
  }

  Future<void> _loadPersistedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((item) => AppNotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _notifications = list;
      }

      final rawKnown = prefs.getStringList(_knownLeadsKey);
      if (rawKnown != null) {
        _knownLeadIds.addAll(rawKnown);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _persistNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
      await prefs.setStringList(_knownLeadsKey, _knownLeadIds.toList());
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      _persistNotifications();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _persistNotifications();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _persistNotifications();
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _persistNotifications();
    notifyListeners();
  }

  void dismissInAppBanner() {
    _bannerDismissTimer?.cancel();
    _activeInAppBanner = null;
    notifyListeners();
  }

  void _triggerInAppBanner(AppNotificationModel notification) {
    _bannerDismissTimer?.cancel();
    _activeInAppBanner = notification;
    notifyListeners();

    // Trigger subtle haptic feedback
    HapticFeedback.mediumImpact();

    // Auto dismiss in-app banner after 5 seconds
    _bannerDismissTimer = Timer(const Duration(seconds: 5), () {
      _activeInAppBanner = null;
      notifyListeners();
    });
  }

  /// Evaluates incoming leads and team messages to detect events:
  /// 1. New Lead received
  /// 2. Inbound customer message
  /// 3. Incoming team chat message
  /// 4. Pipeline status milestone changes (e.g. Won, Completed, Payment Received)
  void checkAndNotifyNewEvents({
    required List<LeadModel> currentLeads,
    required Map<String, int> teamUnread,
    required UserRole currentRole,
  }) {
    if (currentLeads.isEmpty && teamUnread.isEmpty) return;

    if (_isFirstCheck) {
      // First check: Seed the cache with current state without alerting
      for (final lead in currentLeads) {
        _knownLeadIds.add(lead.id);
        _knownLeadStatuses[lead.id] = lead.status;
        _knownCustomerMessageCounts[lead.id] = lead.messages.where((m) => m.from == 'customer').length;
      }
      _knownTeamUnread.addAll(teamUnread);
      _isFirstCheck = false;
      _persistNotifications();
      return;
    }

    final newNotifications = <AppNotificationModel>[];

    // 1. Check for New Leads
    for (final lead in currentLeads) {
      if (!_knownLeadIds.contains(lead.id)) {
        _knownLeadIds.add(lead.id);
        _knownLeadStatuses[lead.id] = lead.status;
        _knownCustomerMessageCounts[lead.id] = lead.messages.where((m) => m.from == 'customer').length;

        // Managers and intake are notified for all new leads
        if (currentRole == UserRole.manager ||
            currentRole == UserRole.superAdmin ||
            currentRole == UserRole.intake) {
          final notif = AppNotificationModel(
            id: 'lead_${lead.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: '🔔 New Lead: ${lead.displayName}',
            body: '${lead.service ?? "Service enquiry"} • ${lead.fullAddress.isNotEmpty ? lead.fullAddress : "Address pending"}',
            category: 'lead',
            timestamp: DateTime.now(),
            leadId: lead.id,
          );
          newNotifications.add(notif);
        }
      } else {
        // Check for Status / Stage Updates
        final prevStatus = _knownLeadStatuses[lead.id];
        if (prevStatus != null && prevStatus != lead.status) {
          _knownLeadStatuses[lead.id] = lead.status;

          // Milestone alerts:
          if (lead.status == 'Won') {
            newNotifications.add(
              AppNotificationModel(
                id: 'status_won_${lead.id}_${DateTime.now().millisecondsSinceEpoch}',
                title: '🎉 Quote Accepted & Won!',
                body: '${lead.displayName} accepted quote for ${lead.displayJobNo}.',
                category: 'schedule',
                timestamp: DateTime.now(),
                leadId: lead.id,
              ),
            );
          } else if (lead.status == 'Job Done') {
            newNotifications.add(
              AppNotificationModel(
                id: 'status_done_${lead.id}_${DateTime.now().millisecondsSinceEpoch}',
                title: '🛠️ Job Completed',
                body: '${lead.displayJobNo} (${lead.displayName}) completed by technician.',
                category: 'finance',
                timestamp: DateTime.now(),
                leadId: lead.id,
              ),
            );
          } else if (lead.status == 'Payment Received') {
            newNotifications.add(
              AppNotificationModel(
                id: 'status_paid_${lead.id}_${DateTime.now().millisecondsSinceEpoch}',
                title: '💰 Payment Received',
                body: 'Full payment confirmed for ${lead.displayName} (${lead.displayJobNo}).',
                category: 'finance',
                timestamp: DateTime.now(),
                leadId: lead.id,
              ),
            );
          }
        }

        // Check for Inbound Customer Messages
        final currentCustomerMsgCount = lead.messages.where((m) => m.from == 'customer').length;
        final prevCustomerMsgCount = _knownCustomerMessageCounts[lead.id] ?? 0;
        if (currentCustomerMsgCount > prevCustomerMsgCount) {
          _knownCustomerMessageCounts[lead.id] = currentCustomerMsgCount;
          final lastCustomerMsg = lead.messages.lastWhere(
            (m) => m.from == 'customer',
            orElse: () => lead.messages.last,
          );
          newNotifications.add(
            AppNotificationModel(
              id: 'msg_${lead.id}_${DateTime.now().millisecondsSinceEpoch}',
              title: '💬 Customer Reply: ${lead.displayName}',
              body: lastCustomerMsg.text.isNotEmpty ? lastCustomerMsg.text : 'New message received',
              category: 'message',
              timestamp: DateTime.now(),
              leadId: lead.id,
            ),
          );
        }
      }
    }

    // 2. Check for Team Chat Messages
    teamUnread.forEach((username, count) {
      final prevCount = _knownTeamUnread[username] ?? 0;
      if (count > prevCount) {
        newNotifications.add(
          AppNotificationModel(
            id: 'team_${username}_${DateTime.now().millisecondsSinceEpoch}',
            title: '👥 Team Message from @$username',
            body: 'You have $count unread team message${count > 1 ? "s" : ""}.',
            category: 'team',
            timestamp: DateTime.now(),
            targetUsername: username,
          ),
        );
      }
      _knownTeamUnread[username] = count;
    });

    // Dispatch detected notifications
    if (newNotifications.isNotEmpty) {
      for (final n in newNotifications) {
        _notifications.insert(0, n);

        // Show local system notification
        _notificationService.showNotification(
          id: n.id.hashCode,
          title: n.title,
          body: n.body,
          payload: {
            'id': n.id,
            'leadId': n.leadId,
            'category': n.category,
            'targetUsername': n.targetUsername,
          },
        );
      }

      // Show in-app banner for the latest notification
      _triggerInAppBanner(newNotifications.first);
      _persistNotifications();
      notifyListeners();
    }
  }

  /// Manually dispatch a test notification (useful for settings/profile screen testing)
  void dispatchTestNotification() {
    final notif = AppNotificationModel(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      title: '🔔 Test Lead Alert',
      body: 'David Wilson • Shower Regrouting • Paddington NSW 2021',
      category: 'lead',
      timestamp: DateTime.now(),
    );

    _notifications.insert(0, notif);
    _notificationService.showNotification(
      id: notif.id.hashCode,
      title: notif.title,
      body: notif.body,
    );
    _triggerInAppBanner(notif);
    _persistNotifications();
    notifyListeners();
  }
}
