class TeamMessageModel {
  final String id;
  final String from;
  final String to;
  final String text;
  final DateTime createdAt;

  const TeamMessageModel({
    required this.id,
    required this.from,
    required this.to,
    required this.text,
    required this.createdAt,
  });

  factory TeamMessageModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return TeamMessageModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class StaffMemberModel {
  final String id;
  final String username;
  final String name;
  final String role;
  final bool active;

  const StaffMemberModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.active = true,
  });

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    return StaffMemberModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? json['username']?.toString() ?? 'Staff',
      role: json['role']?.toString() ?? 'staff',
      active: json['active'] == true || json['active'] == null,
    );
  }

  String get roleDisplay {
    final r = role.toLowerCase();
    switch (r) {
      case 'manager':
      case 'super_admin':
        return 'Manager';
      case 'inspection':
      case 'field':
        return 'Inspection';
      case 'technician':
        return 'Technician';
      case 'finance':
        return 'Finance';
      case 'intake':
        return 'Intake';
      default:
        return role;
    }
  }
}
