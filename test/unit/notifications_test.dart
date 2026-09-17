import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:groutix_app/models/app_notification_model.dart';
import 'package:groutix_app/models/lead_model.dart';
import 'package:groutix_app/models/user_model.dart';
import 'package:groutix_app/providers/notifications_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notifications System Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AppNotificationModel serialization and deserialization', () {
      final now = DateTime.now();
      final model = AppNotificationModel(
        id: 'notif_123',
        title: '🔔 New Lead: John Doe',
        body: 'Balcony Regrouting • Sydney NSW',
        category: 'lead',
        timestamp: now,
        leadId: 'lead_abc',
        isRead: false,
      );

      final json = model.toJson();
      final restored = AppNotificationModel.fromJson(json);

      expect(restored.id, equals('notif_123'));
      expect(restored.title, equals('🔔 New Lead: John Doe'));
      expect(restored.body, equals('Balcony Regrouting • Sydney NSW'));
      expect(restored.category, equals('lead'));
      expect(restored.leadId, equals('lead_abc'));
      expect(restored.isRead, isFalse);
    });

    test('Detects new leads arriving after initial cache seeding', () {
      final provider = NotificationsProvider();

      final initialLead = LeadModel(
        id: 'lead_1',
        name: 'Sarah Connor',
        status: 'Contacted',
        service: 'Shower Sealing',
      );

      // 1. Initial check seeds known leads
      provider.checkAndNotifyNewEvents(
        currentLeads: [initialLead],
        teamUnread: {},
        currentRole: UserRole.manager,
      );

      expect(provider.notifications.length, equals(0));

      // 2. A brand new lead arrives
      final newLead = LeadModel(
        id: 'lead_2',
        name: 'Michael Kyle',
        status: 'New',
        service: 'Tile Regrouting',
        address: '22 George St, Sydney',
      );

      provider.checkAndNotifyNewEvents(
        currentLeads: [initialLead, newLead],
        teamUnread: {},
        currentRole: UserRole.manager,
      );

      // Should alert on the new lead!
      expect(provider.notifications.length, equals(1));
      expect(provider.notifications.first.category, equals('lead'));
      expect(provider.notifications.first.title, contains('Michael Kyle'));
      expect(provider.unreadCount, equals(1));

      // 3. Mark as read
      provider.markAsRead(provider.notifications.first.id);
      expect(provider.unreadCount, equals(0));
    });

    test('Detects status progression milestones such as Won and Job Done', () {
      final provider = NotificationsProvider();

      final lead = LeadModel(
        id: 'lead_10',
        name: 'Emma Stone',
        status: 'Quote Sent',
        jobNo: '1050',
      );

      // Seed initial status
      provider.checkAndNotifyNewEvents(
        currentLeads: [lead],
        teamUnread: {},
        currentRole: UserRole.manager,
      );

      // Customer accepts quote -> status becomes Won
      final wonLead = LeadModel(
        id: 'lead_10',
        name: 'Emma Stone',
        status: 'Won',
        jobNo: '1050',
      );

      provider.checkAndNotifyNewEvents(
        currentLeads: [wonLead],
        teamUnread: {},
        currentRole: UserRole.manager,
      );

      expect(provider.notifications.length, equals(1));
      expect(provider.notifications.first.title, contains('Won'));
    });
  });
}
