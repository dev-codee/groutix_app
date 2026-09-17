class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final String category; // 'lead', 'message', 'team', 'schedule', 'finance'
  final DateTime timestamp;
  bool isRead;
  final String? leadId;
  final String? targetUsername;
  final Map<String, dynamic>? metadata;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.leadId,
    this.targetUsername,
    this.metadata,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    try {
      parsedTime = json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now();
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return AppNotificationModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      category: json['category']?.toString() ?? 'lead',
      timestamp: parsedTime,
      isRead: json['isRead'] == true,
      leadId: json['leadId']?.toString(),
      targetUsername: json['targetUsername']?.toString(),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'leadId': leadId,
      'targetUsername': targetUsername,
      'metadata': metadata,
    };
  }
}
