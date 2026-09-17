import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/inspection_report.dart';
import '../models/lead_model.dart';

class InspectionProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  InspectionReportDoc _currentReport = InspectionReportDoc();
  String? _activeLeadId;
  bool _isSaving = false;
  String? _errorMessage;

  InspectionReportDoc get currentReport => _currentReport;
  String? get activeLeadId => _activeLeadId;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  void initForLead(LeadModel lead, {String? inspectorUsername}) {
    _activeLeadId = lead.id;
    _errorMessage = null;

    final existing = lead.inspectionReport;
    final defaultDate = (lead.inspectionAt != null && lead.inspectionAt!.length >= 10)
        ? lead.inspectionAt!.substring(0, 10)
        : DateTime.now().toIso8601String().substring(0, 10);

    if (existing != null) {
      _currentReport = existing.copyWith(
        customerName: existing.customerName ?? lead.displayName,
        propertyAddress: existing.propertyAddress ?? lead.fullAddress,
        leadJobNo: existing.leadJobNo ?? lead.displayJobNo,
        inspectionDate: existing.inspectionDate ?? defaultDate,
        inspectorName: existing.inspectorName ?? inspectorUsername ?? 'Inspection Specialist',
      );
    } else {
      _currentReport = InspectionReportDoc(
        customerName: lead.displayName,
        propertyAddress: lead.fullAddress,
        leadJobNo: lead.displayJobNo,
        inspectionDate: defaultDate,
        inspectorName: inspectorUsername ?? 'Inspection Specialist',
        room: 'Main Bathroom',
        findings: {},
        quoteBuildFromReport: 'YES',
        warrantyEligible: 'YES',
        status: 'draft',
      );
    }
    notifyListeners();
  }

  void setFinding(String itemId, String value) {
    final findings = Map<String, String>.from(_currentReport.findings);
    // Toggle off if selected again
    if (findings[itemId] == value) {
      findings[itemId] = '';
    } else {
      findings[itemId] = value;
    }
    _currentReport = _currentReport.copyWith(findings: findings);
    notifyListeners();
  }

  void updateField({
    String? room,
    String? otherDetails,
    String? estimatedTime,
    String? quoteBuildFromReport,
    String? warrantyEligible,
    String? inspectorNotes,
    String? inspectorSignature,
  }) {
    _currentReport = _currentReport.copyWith(
      room: room,
      otherDetails: otherDetails,
      estimatedTime: estimatedTime,
      quoteBuildFromReport: quoteBuildFromReport,
      warrantyEligible: warrantyEligible,
      inspectorNotes: inspectorNotes,
      inspectorSignature: inspectorSignature,
    );
    notifyListeners();
  }

  Future<bool> saveReport({bool markCompleted = false}) async {
    if (_activeLeadId == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedReport = _currentReport.copyWith(
        status: markCompleted ? 'completed' : _currentReport.status,
        completedAt: markCompleted ? DateTime.now().toIso8601String() : _currentReport.completedAt,
        updatedAt: DateTime.now().toIso8601String(),
      );

      final payload = <String, dynamic>{
        'inspectionReport': updatedReport.toJson(),
      };

      if (markCompleted) {
        payload['status'] = 'Inspection Completed';
      }

      final response = await _api.patch(
        ApiEndpoints.submissionDetail(_activeLeadId!),
        data: payload,
      );

      if (response.data != null && response.data['ok'] == true) {
        _currentReport = updatedReport;
        _isSaving = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Could not save report.';
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
