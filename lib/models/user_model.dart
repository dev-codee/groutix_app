enum UserRole {
  manager,
  inspection,
  technician,
  finance,
  intake,
  superAdmin;

  static UserRole fromString(String? roleStr) {
    final clean = (roleStr ?? '').trim().toLowerCase();
    switch (clean) {
      case 'inspection':
      case 'field':
        return UserRole.inspection;
      case 'technician':
        return UserRole.technician;
      case 'finance':
        return UserRole.finance;
      case 'intake':
        return UserRole.intake;
      case 'super_admin':
        return UserRole.superAdmin;
      case 'manager':
      default:
        return UserRole.manager;
    }
  }

  String get label {
    switch (this) {
      case UserRole.manager:
      case UserRole.superAdmin:
        return 'Business Manager';
      case UserRole.inspection:
        return 'Inspection Specialist';
      case UserRole.technician:
        return 'Field Technician';
      case UserRole.finance:
        return 'Finance & Completion';
      case UserRole.intake:
        return 'Intake & Leads';
    }
  }

  String get rawValue {
    switch (this) {
      case UserRole.manager:
        return 'manager';
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.inspection:
        return 'inspection';
      case UserRole.technician:
        return 'technician';
      case UserRole.finance:
        return 'finance';
      case UserRole.intake:
        return 'intake';
    }
  }
}

class UserModel {
  final String username;
  final String? name;
  final UserRole role;
  final String? token;

  UserModel({
    required this.username,
    this.name,
    required this.role,
    this.token,
  });

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!;
    if (username.contains('@')) {
      final part = username.split('@').first;
      if (part.toLowerCase().contains('groutixmanager') || part.toLowerCase() == 'manager') {
        return 'Manager';
      }
      return part;
    }
    return username;
  }

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      username: json['username'] ?? json['u'] ?? '',
      name: json['name'],
      role: UserRole.fromString(json['role']),
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'name': name,
        'role': role.rawValue,
        'token': token,
      };
}
