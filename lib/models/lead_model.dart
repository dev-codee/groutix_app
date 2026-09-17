import 'inspection_report.dart';
import 'quote_item.dart';
import '../core/utils/date_formatter.dart';

class LeadPhoto {
  final String name;
  final String? url;
  final String? secureUrl;
  final String? publicId;
  final String? dataUrl;
  final String? added;
  final String? uploadedBy;

  LeadPhoto({
    required this.name,
    this.url,
    this.secureUrl,
    this.publicId,
    this.dataUrl,
    this.added,
    this.uploadedBy,
  });

  String get displayUrl => secureUrl ?? url ?? dataUrl ?? '';

  factory LeadPhoto.fromJson(Map<String, dynamic> json) {
    return LeadPhoto(
      name: json['name']?.toString() ?? 'photo',
      url: json['url']?.toString(),
      secureUrl: json['secureUrl']?.toString(),
      publicId: json['publicId']?.toString(),
      dataUrl: json['dataUrl']?.toString(),
      added: json['added']?.toString(),
      uploadedBy: json['uploadedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (url != null) 'url': url,
        if (secureUrl != null) 'secureUrl': secureUrl,
        if (publicId != null) 'publicId': publicId,
        if (dataUrl != null) 'dataUrl': dataUrl,
        if (added != null) 'added': added,
        if (uploadedBy != null) 'uploadedBy': uploadedBy,
      };
}

class ActivityEntry {
  final String time;
  final String actor;
  final String action;
  final String? detail;

  ActivityEntry({
    required this.time,
    required this.actor,
    required this.action,
    this.detail,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      time: json['time']?.toString() ?? '',
      actor: json['actor']?.toString() ?? 'staff',
      action: json['action']?.toString() ?? '',
      detail: json['detail']?.toString(),
    );
  }
}

class TenantDoc {
  final String name;
  final String phone;
  final String? email;

  TenantDoc({required this.name, required this.phone, this.email});

  factory TenantDoc.fromJson(Map<String, dynamic> json) => TenantDoc(
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
      };
}

class CustomerMessage {
  final String id;
  final String from;
  final String? channel;
  final String text;
  final String time;

  CustomerMessage({
    required this.id,
    required this.from,
    this.channel,
    required this.text,
    required this.time,
  });

  factory CustomerMessage.fromJson(Map<String, dynamic> json) => CustomerMessage(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        from: json['from']?.toString() ?? 'customer',
        channel: json['channel']?.toString(),
        text: json['text']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': from,
        if (channel != null) 'channel': channel,
        'text': text,
        'time': time,
      };
}

class LeadModel {
  final String id;
  final String? jobNo;
  final String type;
  final String status;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? service;
  final String? areas;
  final String? damagedTiles;
  final String? leaking;
  final String? customerType;
  final String? agency;
  final String? notes;
  final String? message;
  final String? assigned;
  final String? technician;
  final String? technicianId;
  final double? quoteAmount;
  final List<QuoteItem> quoteItems;
  final String? quoteScope;
  final String? quoteNumber;
  final String? inspectionAt;
  final String? jobAt;
  final int? jobTotalDays;
  final int? jobDaysDone;
  final InspectionReportDoc? inspectionReport;
  final List<LeadPhoto> photos;
  final String? invoiceNumber;
  final String? invoiceStatus;
  final String? invoiceSentAt;
  final double? amountPaid;
  final String? paymentType;
  final bool? warrantyProvided;
  final String? contacted;
  final String? follow;
  final String? quoteAcceptedAt;
  final String? quoteSignedName;
  final String? quoteSignedAt;
  final List<TenantDoc> tenants;
  final List<CustomerMessage> messages;
  final List<ActivityEntry> activity;
  final String? createdAt;

  LeadModel({
    required this.id,
    this.jobNo,
    this.type = 'quote',
    this.status = 'New',
    this.name,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.service,
    this.areas,
    this.damagedTiles,
    this.leaking,
    this.customerType,
    this.agency,
    this.notes,
    this.message,
    this.assigned,
    this.technician,
    this.technicianId,
    this.quoteAmount,
    List<QuoteItem>? quoteItems,
    this.quoteScope,
    this.quoteNumber,
    this.inspectionAt,
    this.jobAt,
    this.jobTotalDays,
    this.jobDaysDone,
    this.inspectionReport,
    List<LeadPhoto>? photos,
    this.invoiceNumber,
    this.invoiceStatus,
    this.invoiceSentAt,
    this.amountPaid,
    this.paymentType,
    this.warrantyProvided,
    this.contacted,
    this.follow,
    this.quoteAcceptedAt,
    this.quoteSignedName,
    this.quoteSignedAt,
    List<TenantDoc>? tenants,
    List<CustomerMessage>? messages,
    List<ActivityEntry>? activity,
    this.createdAt,
  })  : quoteItems = quoteItems ?? [],
        photos = photos ?? [],
        tenants = tenants ?? [],
        messages = messages ?? [],
        activity = activity ?? [];

  String get displayJobNo {
    if (jobNo != null && jobNo!.trim().isNotEmpty) {
      String clean = jobNo!.trim();
      clean = clean.replaceAll(RegExp(r'^(jobno|job|no)[-:\s.]*', caseSensitive: false), '');
      clean = clean.replaceAll(RegExp(r'^(jobno|job|no)[-:\s.]*', caseSensitive: false), '');
      if (clean.isNotEmpty) {
        return '#$clean';
      }
      return '#${jobNo!.trim()}';
    }
    final fallback = id.length >= 4 ? id.substring(0, 4).toUpperCase() : id;
    return '#$fallback';
  }

  String get displayName => (name != null && name!.trim().isNotEmpty) ? name! : 'Unnamed Customer';

  String? get serviceType => service;

  String get fullAddress {
    final parts = [address, city, state].where((p) => p != null && p.trim().isNotEmpty);
    return parts.isEmpty ? 'No address provided' : parts.join(', ');
  }

  String get displayScheduleTime {
    final v = jobAt ?? inspectionAt ?? createdAt;
    if (v == null || v.isEmpty) return 'Not scheduled';
    return DateFormatter.formatAppt(v);
  }

  bool get hasInspection => inspectionAt != null && inspectionAt!.isNotEmpty;
  bool get hasJob => jobAt != null && jobAt!.isNotEmpty;

  LeadModel copyWith({
    String? id,
    String? jobNo,
    String? type,
    String? status,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? service,
    String? areas,
    String? damagedTiles,
    String? leaking,
    String? customerType,
    String? agency,
    String? notes,
    String? message,
    String? assigned,
    String? technician,
    String? technicianId,
    double? quoteAmount,
    List<QuoteItem>? quoteItems,
    String? quoteScope,
    String? quoteNumber,
    String? inspectionAt,
    String? jobAt,
    int? jobTotalDays,
    int? jobDaysDone,
    InspectionReportDoc? inspectionReport,
    List<LeadPhoto>? photos,
    String? invoiceNumber,
    String? invoiceStatus,
    String? invoiceSentAt,
    double? amountPaid,
    String? paymentType,
    bool? warrantyProvided,
    String? contacted,
    String? follow,
    String? quoteAcceptedAt,
    String? quoteSignedName,
    String? quoteSignedAt,
    List<TenantDoc>? tenants,
    List<CustomerMessage>? messages,
    List<ActivityEntry>? activity,
    String? createdAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      jobNo: jobNo ?? this.jobNo,
      type: type ?? this.type,
      status: status ?? this.status,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      service: service ?? this.service,
      areas: areas ?? this.areas,
      damagedTiles: damagedTiles ?? this.damagedTiles,
      leaking: leaking ?? this.leaking,
      customerType: customerType ?? this.customerType,
      agency: agency ?? this.agency,
      notes: notes ?? this.notes,
      message: message ?? this.message,
      assigned: assigned ?? this.assigned,
      technician: technician ?? this.technician,
      technicianId: technicianId ?? this.technicianId,
      quoteAmount: quoteAmount ?? this.quoteAmount,
      quoteItems: quoteItems ?? this.quoteItems,
      quoteScope: quoteScope ?? this.quoteScope,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      inspectionAt: inspectionAt ?? this.inspectionAt,
      jobAt: jobAt ?? this.jobAt,
      jobTotalDays: jobTotalDays ?? this.jobTotalDays,
      jobDaysDone: jobDaysDone ?? this.jobDaysDone,
      inspectionReport: inspectionReport ?? this.inspectionReport,
      photos: photos ?? this.photos,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceStatus: invoiceStatus ?? this.invoiceStatus,
      invoiceSentAt: invoiceSentAt ?? this.invoiceSentAt,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentType: paymentType ?? this.paymentType,
      warrantyProvided: warrantyProvided ?? this.warrantyProvided,
      contacted: contacted ?? this.contacted,
      follow: follow ?? this.follow,
      quoteAcceptedAt: quoteAcceptedAt ?? this.quoteAcceptedAt,
      quoteSignedName: quoteSignedName ?? this.quoteSignedName,
      quoteSignedAt: quoteSignedAt ?? this.quoteSignedAt,
      tenants: tenants ?? this.tenants,
      messages: messages ?? this.messages,
      activity: activity ?? this.activity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['quoteItems'];
    final List<QuoteItem> items = [];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(QuoteItem.fromJson(item));
        }
      }
    }

    final rawPhotos = json['photos'];
    final List<LeadPhoto> parsedPhotos = [];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        if (p is Map<String, dynamic>) {
          parsedPhotos.add(LeadPhoto.fromJson(p));
        }
      }
    }

    final rawActivity = json['activity'];
    final List<ActivityEntry> parsedActivity = [];
    if (rawActivity is List) {
      for (final a in rawActivity) {
        if (a is Map<String, dynamic>) {
          parsedActivity.add(ActivityEntry.fromJson(a));
        }
      }
    }

    final rawTenants = json['tenants'];
    final List<TenantDoc> parsedTenants = [];
    if (rawTenants is List) {
      for (final t in rawTenants) {
        if (t is Map<String, dynamic>) {
          parsedTenants.add(TenantDoc.fromJson(t));
        }
      }
    }

    final rawMessages = json['messages'];
    final List<CustomerMessage> parsedMessages = [];
    if (rawMessages is List) {
      for (final m in rawMessages) {
        if (m is Map<String, dynamic>) {
          parsedMessages.add(CustomerMessage.fromJson(m));
        }
      }
    }

    return LeadModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      jobNo: json['jobNo']?.toString(),
      type: json['type']?.toString() ?? 'quote',
      status: json['status']?.toString() ?? 'New',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      service: json['service']?.toString(),
      areas: json['areas']?.toString(),
      damagedTiles: json['damagedTiles']?.toString(),
      leaking: json['leaking']?.toString(),
      customerType: json['customerType']?.toString(),
      agency: json['agency']?.toString(),
      notes: json['notes']?.toString(),
      message: json['message']?.toString(),
      assigned: json['assigned']?.toString(),
      technician: json['technician']?.toString(),
      technicianId: json['technicianId']?.toString(),
      quoteAmount: (json['quoteAmount'] as num?)?.toDouble() ?? (json['quoteTotal'] as num?)?.toDouble(),
      quoteItems: items,
      quoteScope: json['quoteScope']?.toString(),
      quoteNumber: json['quoteNumber']?.toString(),
      inspectionAt: json['inspectionAt']?.toString(),
      jobAt: json['jobAt']?.toString(),
      jobTotalDays: (json['jobTotalDays'] as num?)?.toInt(),
      jobDaysDone: (json['jobDaysDone'] as num?)?.toInt(),
      inspectionReport: json['inspectionReport'] != null
          ? InspectionReportDoc.fromJson(json['inspectionReport'] as Map<String, dynamic>)
          : null,
      photos: parsedPhotos,
      invoiceNumber: json['invoiceNumber']?.toString(),
      invoiceStatus: json['invoiceStatus']?.toString(),
      invoiceSentAt: json['invoiceSentAt']?.toString(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      paymentType: json['paymentType']?.toString(),
      warrantyProvided: json['warrantyProvided'] as bool?,
      contacted: json['contacted']?.toString(),
      follow: json['follow']?.toString(),
      quoteAcceptedAt: json['quoteAcceptedAt']?.toString(),
      quoteSignedName: json['quoteSignedName']?.toString(),
      quoteSignedAt: json['quoteSignedAt']?.toString(),
      tenants: parsedTenants,
      messages: parsedMessages,
      activity: parsedActivity,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (jobNo != null) 'jobNo': jobNo,
        'type': type,
        'status': status,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (service != null) 'service': service,
        if (areas != null) 'areas': areas,
        if (damagedTiles != null) 'damagedTiles': damagedTiles,
        if (leaking != null) 'leaking': leaking,
        if (customerType != null) 'customerType': customerType,
        if (agency != null) 'agency': agency,
        if (notes != null) 'notes': notes,
        if (message != null) 'message': message,
        if (assigned != null) 'assigned': assigned,
        if (technician != null) 'technician': technician,
        if (technicianId != null) 'technicianId': technicianId,
        if (quoteAmount != null) 'quoteAmount': quoteAmount,
        'quoteItems': quoteItems.map((i) => i.toJson()).toList(),
        if (quoteScope != null) 'quoteScope': quoteScope,
        if (quoteNumber != null) 'quoteNumber': quoteNumber,
        if (inspectionAt != null) 'inspectionAt': inspectionAt,
        if (jobAt != null) 'jobAt': jobAt,
        if (jobTotalDays != null) 'jobTotalDays': jobTotalDays,
        if (jobDaysDone != null) 'jobDaysDone': jobDaysDone,
        if (inspectionReport != null) 'inspectionReport': inspectionReport!.toJson(),
        'photos': photos.map((p) => p.toJson()).toList(),
        if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
        if (invoiceStatus != null) 'invoiceStatus': invoiceStatus,
        if (invoiceSentAt != null) 'invoiceSentAt': invoiceSentAt,
        if (amountPaid != null) 'amountPaid': amountPaid,
        if (paymentType != null) 'paymentType': paymentType,
        if (warrantyProvided != null) 'warrantyProvided': warrantyProvided,
        if (contacted != null) 'contacted': contacted,
        if (follow != null) 'follow': follow,
        if (quoteAcceptedAt != null) 'quoteAcceptedAt': quoteAcceptedAt,
        if (quoteSignedName != null) 'quoteSignedName': quoteSignedName,
        if (quoteSignedAt != null) 'quoteSignedAt': quoteSignedAt,
        if (createdAt != null) 'createdAt': createdAt,
      };
}
