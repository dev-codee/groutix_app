class InspectionItem {
  final String id;
  final String label;

  const InspectionItem({required this.id, required this.label});
}

class InspectionSection {
  final String key;
  final String title;
  final List<InspectionItem> items;

  const InspectionSection({
    required this.key,
    required this.title,
    required this.items,
  });
}

const List<InspectionSection> kInspectionSections = [
  InspectionSection(
    key: 'propertyRoom',
    title: 'Property / Room',
    items: [
      InspectionItem(id: 'main_bathroom', label: 'Main Bathroom'),
      InspectionItem(id: 'ensuite', label: 'Ensuite'),
      InspectionItem(id: 'guest_bathroom', label: 'Guest Bathroom'),
      InspectionItem(id: 'balcony_exterior', label: 'Balcony / Exterior'),
      InspectionItem(id: 'single_shower', label: 'Single Shower'),
      InspectionItem(id: 'double_shower', label: 'Double Shower'),
    ],
  ),
  InspectionSection(
    key: 'areaWorkCoverage',
    title: 'Area / Work Coverage',
    items: [
      InspectionItem(id: 'shower_walls', label: 'Shower Walls'),
      InspectionItem(id: 'shower_floor', label: 'Shower Floor'),
      InspectionItem(id: 'bath_area', label: 'Bath Area'),
      InspectionItem(id: 'shower_pan_base', label: 'Shower Pan / Base'),
      InspectionItem(id: 'floor_only', label: 'Floor Only'),
      InspectionItem(id: 'walls_only', label: 'Walls Only'),
      InspectionItem(id: 'walls_and_floor', label: 'Walls & Floor'),
      InspectionItem(id: 'walls_to_pan', label: 'Walls to Pan'),
      InspectionItem(id: 'ceiling_height', label: 'Ceiling Height'),
      InspectionItem(id: 'shower_screen_height', label: 'Shower Screen Height / Approx. 2.1 m'),
    ],
  ),
  InspectionSection(
    key: 'waterLeakage',
    title: 'Water / Leakage',
    items: [
      InspectionItem(id: 'leakage_water_ingress', label: 'Leakage / Water Ingress'),
      InspectionItem(id: 'water_staining', label: 'Water Staining / Discolouration'),
      InspectionItem(id: 'moisture_shower_base', label: 'Moisture Beneath Shower Base'),
      InspectionItem(id: 'balcony_water_ingress', label: 'Known Balcony Waterproofing / Leak Issue'),
    ],
  ),
  InspectionSection(
    key: 'groutCondition',
    title: 'Grout Condition',
    items: [
      InspectionItem(id: 'failed_cracked_grout', label: 'Failed / Cracked / Missing Grout'),
      InspectionItem(id: 'mould_black_grout', label: 'Mould / Black Grout'),
      InspectionItem(id: 'grout_joints_prep', label: 'Grout Joint Preparation'),
      InspectionItem(id: 'movement_joint_condition', label: 'Movement Joint Condition'),
    ],
  ),
  InspectionSection(
    key: 'tilesSurface',
    title: 'Tiles / Surface',
    items: [
      InspectionItem(id: 'loose_damaged_tiles', label: 'Loose / Damaged Tiles'),
      InspectionItem(id: 'cracked_tile_repair', label: 'Cracked Tile Repair'),
      InspectionItem(id: 'mosaic_tiles', label: 'Mosaic Tiles'),
      InspectionItem(id: 'dirt_surface_contamination', label: 'Dirt / Surface Contamination'),
      InspectionItem(id: 'deep_staining_contamination', label: 'Deep Staining / Embedded Contamination'),
    ],
  ),
  InspectionSection(
    key: 'siliconeSealing',
    title: 'Silicone / Sealing',
    items: [
      InspectionItem(id: 'failed_silicone', label: 'Failed Silicone / Sealant'),
      InspectionItem(id: 'tile_to_tile', label: 'Tile-to-Tile'),
      InspectionItem(id: 'tile_to_floor', label: 'Tile-to-Floor'),
      InspectionItem(id: 'tile_to_bath', label: 'Tile-to-Bath'),
      InspectionItem(id: 'tile_to_pan', label: 'Tile-to-Pan'),
      InspectionItem(id: 'perimeter_joints', label: 'Perimeter Joints'),
      InspectionItem(id: 'plumbing_penetrations', label: 'Plumbing Penetrations'),
      InspectionItem(id: 'shower_screen_vertical_io', label: 'Shower Screen Vertical Inside/Outside'),
      InspectionItem(id: 'shower_screen_horizontal_io', label: 'Shower Screen Horizontal Inside/Outside'),
    ],
  ),
  InspectionSection(
    key: 'treatmentAdditionalWork',
    title: 'Treatment / Additional Work',
    items: [
      InspectionItem(id: 'mould_treatment', label: 'Mould Treatment'),
      InspectionItem(id: 'pressure_washing_prep', label: 'Pressure Washing / Surface Preparation'),
      InspectionItem(id: 'penetrating_grout_sealer', label: 'Penetrating Grout Sealer'),
      InspectionItem(id: 'epoxy_grout_upgrade', label: 'Epoxy Grout Upgrade'),
      InspectionItem(id: 'shower_screen_replacement', label: 'Shower Screen Replacement'),
    ],
  ),
  InspectionSection(
    key: 'junctionsMovement',
    title: 'Junctions / Movement',
    items: [
      InspectionItem(id: 'wall_to_floor', label: 'Wall-to-Floor'),
      InspectionItem(id: 'wall_to_wall', label: 'Wall-to-Wall / Tile-to-Tile'),
      InspectionItem(id: 'movement_joints', label: 'Movement Joints'),
    ],
  ),
];

class InspectionSummary {
  final int yesCount;
  final int noCount;
  final int unansweredCount;
  final int totalItems;

  const InspectionSummary({
    required this.yesCount,
    required this.noCount,
    required this.unansweredCount,
    required this.totalItems,
  });
}

class InspectionReportDoc {
  final String? customerName;
  final String? inspectionDate;
  final String? inspectorName;
  final String? propertyAddress;
  final String? leadJobNo;
  final String? room;
  final Map<String, String> findings; // id -> 'YES' | 'NO' | ''
  final String? otherDetails;
  final String? estimatedTime;
  final String? quoteBuildFromReport;
  final String? warrantyEligible;
  final String? inspectorNotes;
  final String? inspectorSignature;
  final String? customerAcknowledgement;
  final String? suggestedTechnician;
  final String status; // 'draft' | 'completed'
  final String? completedAt;
  final String? updatedAt;

  InspectionReportDoc({
    this.customerName,
    this.inspectionDate,
    this.inspectorName,
    this.propertyAddress,
    this.leadJobNo,
    this.room,
    Map<String, String>? findings,
    this.otherDetails,
    this.estimatedTime,
    this.quoteBuildFromReport = 'YES',
    this.warrantyEligible = 'YES',
    this.inspectorNotes,
    this.inspectorSignature,
    this.customerAcknowledgement,
    this.suggestedTechnician,
    this.status = 'draft',
    this.completedAt,
    this.updatedAt,
  }) : findings = findings ?? {};

  InspectionSummary get summary {
    int yes = 0;
    int no = 0;
    int total = 0;

    for (final section in kInspectionSections) {
      for (final item in section.items) {
        total++;
        final val = findings[item.id];
        if (val == 'YES') yes++;
        if (val == 'NO') no++;
      }
    }
    return InspectionSummary(
      yesCount: yes,
      noCount: no,
      unansweredCount: total - (yes + no),
      totalItems: total,
    );
  }

  InspectionReportDoc copyWith({
    String? customerName,
    String? inspectionDate,
    String? inspectorName,
    String? propertyAddress,
    String? leadJobNo,
    String? room,
    Map<String, String>? findings,
    String? otherDetails,
    String? estimatedTime,
    String? quoteBuildFromReport,
    String? warrantyEligible,
    String? inspectorNotes,
    String? inspectorSignature,
    String? customerAcknowledgement,
    String? suggestedTechnician,
    String? status,
    String? completedAt,
    String? updatedAt,
  }) {
    return InspectionReportDoc(
      customerName: customerName ?? this.customerName,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      inspectorName: inspectorName ?? this.inspectorName,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      leadJobNo: leadJobNo ?? this.leadJobNo,
      room: room ?? this.room,
      findings: findings ?? Map<String, String>.from(this.findings),
      otherDetails: otherDetails ?? this.otherDetails,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      quoteBuildFromReport: quoteBuildFromReport ?? this.quoteBuildFromReport,
      warrantyEligible: warrantyEligible ?? this.warrantyEligible,
      inspectorNotes: inspectorNotes ?? this.inspectorNotes,
      inspectorSignature: inspectorSignature ?? this.inspectorSignature,
      customerAcknowledgement: customerAcknowledgement ?? this.customerAcknowledgement,
      suggestedTechnician: suggestedTechnician ?? this.suggestedTechnician,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory InspectionReportDoc.fromJson(Map<String, dynamic>? json) {
    if (json == null) return InspectionReportDoc();

    final rawFindings = json['findings'];
    final Map<String, String> parsedFindings = {};
    if (rawFindings is Map) {
      rawFindings.forEach((k, v) {
        if (v != null) parsedFindings[k.toString()] = v.toString();
      });
    }

    return InspectionReportDoc(
      customerName: json['customerName']?.toString(),
      inspectionDate: json['inspectionDate']?.toString(),
      inspectorName: json['inspectorName']?.toString(),
      propertyAddress: json['propertyAddress']?.toString(),
      leadJobNo: json['leadJobNo']?.toString(),
      room: json['room']?.toString(),
      findings: parsedFindings,
      otherDetails: json['otherDetails']?.toString(),
      estimatedTime: json['estimatedTime']?.toString(),
      quoteBuildFromReport: json['quoteBuildFromReport']?.toString() ?? 'YES',
      warrantyEligible: json['warrantyEligible']?.toString() ?? 'YES',
      inspectorNotes: json['inspectorNotes']?.toString(),
      inspectorSignature: json['inspectorSignature']?.toString(),
      customerAcknowledgement: json['customerAcknowledgement']?.toString(),
      suggestedTechnician: json['suggestedTechnician']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      completedAt: json['completedAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (customerName != null) 'customerName': customerName,
        if (inspectionDate != null) 'inspectionDate': inspectionDate,
        if (inspectorName != null) 'inspectorName': inspectorName,
        if (propertyAddress != null) 'propertyAddress': propertyAddress,
        if (leadJobNo != null) 'leadJobNo': leadJobNo,
        if (room != null) 'room': room,
        'findings': findings,
        if (otherDetails != null) 'otherDetails': otherDetails,
        if (estimatedTime != null) 'estimatedTime': estimatedTime,
        'quoteBuildFromReport': quoteBuildFromReport ?? 'YES',
        'warrantyEligible': warrantyEligible ?? 'YES',
        if (inspectorNotes != null) 'inspectorNotes': inspectorNotes,
        if (inspectorSignature != null) 'inspectorSignature': inspectorSignature,
        if (customerAcknowledgement != null) 'customerAcknowledgement': customerAcknowledgement,
        if (suggestedTechnician != null) 'suggestedTechnician': suggestedTechnician,
        'status': status,
        if (completedAt != null) 'completedAt': completedAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
      };
}
