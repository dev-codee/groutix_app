import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../core/utils/geo_helper.dart';
import '../models/lead_model.dart';
import '../models/user_model.dart';

class LeadsProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<LeadModel> _leads = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedStatusFilter;

  List<LeadModel> get leads => _leads;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedStatusFilter => _selectedStatusFilter;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String? status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  // Filter leads based on current user role and active search/filter
  List<LeadModel> getScopedLeads(UserRole role) {
    return _leads.where((lead) {
      // 1. Role scoping
      bool roleMatch = true;
      switch (role) {
        case UserRole.manager:
        case UserRole.superAdmin:
          roleMatch = true;
          break;
        case UserRole.inspection:
          roleMatch = [
            'Inspection Booked',
            'Inspection En Route',
            'Inspection Arrived',
            'Inspection In Progress',
            'Inspection Completed',
            'Quote Pending',
          ].contains(lead.status);
          break;
        case UserRole.technician:
          roleMatch = [
            'Won',
            'Job Booked',
            'Scheduled',
            'Job Confirmed',
            'Job En Route',
            'Job Arrived',
            'Job Started',
            'Job In Progress',
            'Job Done',
            'Completed',
          ].contains(lead.status);
          break;
        case UserRole.finance:
          roleMatch = [
            'Job Done',
            'Invoice Sent',
            'Payment Pending',
            'Payment Received',
            'Warranty Sent',
            'Completed',
          ].contains(lead.status);
          break;
        case UserRole.intake:
          roleMatch = [
            'New',
            'Contacted',
            'Waiting for Info',
            'Inspection Booked',
            'Inspection Completed',
            'Quote Pending',
            'Quote Sent',
            'Negotiation',
            'Won',
            'Job Booked',
            'Lost',
          ].contains(lead.status);
          break;
      }

      if (!roleMatch) return false;

      // 2. Status pill filter if selected
      if (_selectedStatusFilter != null && _selectedStatusFilter!.isNotEmpty) {
        if (lead.status != _selectedStatusFilter) return false;
      }

      // 3. Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchJobNo = lead.displayJobNo.toLowerCase().contains(q);
        final matchName = (lead.name ?? '').toLowerCase().contains(q);
        final matchPhone = (lead.phone ?? '').toLowerCase().contains(q);
        final matchAddress = (lead.address ?? '').toLowerCase().contains(q);
        final matchService = (lead.service ?? '').toLowerCase().contains(q);
        return matchJobNo || matchName || matchPhone || matchAddress || matchService;
      }

      return true;
    }).toList();
  }

  Future<void> fetchLeads({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _api.get(
        ApiEndpoints.submissions,
        queryParameters: {'all': 'true'},
      );

      final data = response.data;
      List? rawItems;
      if (data != null) {
        if (data is Map && data['items'] is List) {
          rawItems = data['items'] as List;
        } else if (data is List) {
          rawItems = data;
        }
      }

      if (rawItems != null) {
        _leads = rawItems
            .map((item) => LeadModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _errorMessage = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('LeadsProvider.fetchLeads error: $e');
      if (e is ApiException && e.statusCode == 401) {
        _errorMessage = 'Session expired or unauthorized. Please sign out and log in again.';
      } else {
        _errorMessage = e.toString();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  LeadModel? getLeadById(String id) {
    try {
      return _leads.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateLeadField(String leadId, Map<String, dynamic> updates) async {
    try {
      final response = await _api.patch(
        ApiEndpoints.submissionDetail(leadId),
        data: updates,
      );

      if (response.data != null && response.data['ok'] == true) {
        // Optimistically update local model
        final index = _leads.indexWhere((l) => l.id == leadId);
        if (index != -1) {
          final current = _leads[index];
          final updated = current.copyWith(
            status: updates['status']?.toString() ?? current.status,
            assigned: updates['assigned']?.toString() ?? current.assigned,
            technician: updates['technician']?.toString() ?? current.technician,
            notes: updates['notes']?.toString() ?? current.notes,
            service: updates['service']?.toString() ?? current.service,
            areas: updates['areas']?.toString() ?? current.areas,
            inspectionAt: updates['inspectionAt']?.toString() ?? current.inspectionAt,
            jobAt: updates['jobAt']?.toString() ?? current.jobAt,
            contacted: updates['contacted']?.toString() ?? current.contacted,
            follow: updates['follow']?.toString() ?? current.follow,
            quoteScope: updates['quoteScope']?.toString() ?? current.quoteScope,
            jobDaysDone: updates['jobDaysDone'] is int ? updates['jobDaysDone'] : current.jobDaysDone,
            invoiceStatus: updates['invoiceStatus']?.toString() ?? current.invoiceStatus,
            warrantyProvided: updates['warrantyProvided'] is bool ? updates['warrantyProvided'] : current.warrantyProvided,
          );
          _leads[index] = updated;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> logCall(String leadId, String outcome, {String? note}) async {
    try {
      final payload = <String, dynamic>{'outcome': outcome};
      if (note != null) payload['note'] = note;
      final response = await _api.post(
        ApiEndpoints.leadCall(leadId),
        data: payload,
      );

      if (response.data != null && response.data['ok'] == true) {
        // Refresh silently so the new activity entry and any auto-advanced status are loaded
        await fetchLeads(silent: true);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendLeadEmail(
    String leadId, {
    required String subject,
    required String text,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.leadEmail(leadId),
        data: {'subject': subject, 'text': text},
      );

      if (response.data != null && (response.data['ok'] == true || response.data['message'] != null)) {
        if (response.data['message'] != null) {
          final newMsg = CustomerMessage.fromJson(response.data['message'] as Map<String, dynamic>);
          final index = _leads.indexWhere((l) => l.id == leadId);
          if (index != -1) {
            final lead = _leads[index];
            _leads[index] = lead.copyWith(messages: [...lead.messages, newMsg]);
            notifyListeners();
          }
        } else {
          await fetchLeads(silent: true);
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendLeadSms(
    String leadId, {
    required String text,
  }) async {
    try {
      final response = await _api.post(
        ApiEndpoints.leadSms(leadId),
        data: {'text': text},
      );

      if (response.data != null && (response.data['ok'] == true || response.data['message'] != null)) {
        if (response.data['message'] != null) {
          final newMsg = CustomerMessage.fromJson(response.data['message'] as Map<String, dynamic>);
          final index = _leads.indexWhere((l) => l.id == leadId);
          if (index != -1) {
            final lead = _leads[index];
            _leads[index] = lead.copyWith(messages: [...lead.messages, newMsg]);
            notifyListeners();
          }
        } else {
          await fetchLeads(silent: true);
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> notifyOnTheWay(String leadId, {required String eventType}) async {
    try {
      final pos = await GeoHelper.getCurrentLocation();
      final body = {
        'leadId': leadId,
        'eventType': eventType, // 'en_route' or 'arrived'
        'lat': pos?.latitude,
        'lng': pos?.longitude,
      };

      final response = await _api.post(ApiEndpoints.onTheWay, data: body);
      if (response.data != null && response.data['ok'] == true) {
        // Automatically transition lead status
        final newStatus = eventType == 'en_route' ? 'Inspection En Route' : 'Inspection Arrived';
        await updateLeadField(leadId, {'status': newStatus});
        return {
          'ok': true,
          'eta': response.data['eta'],
          'etaMinutes': response.data['etaMinutes'],
        };
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> notifyTechnicianOnTheWay(String leadId, {required String eventType}) async {
    try {
      final pos = await GeoHelper.getCurrentLocation();
      final body = {
        'leadId': leadId,
        'eventType': eventType,
        'lat': pos?.latitude,
        'lng': pos?.longitude,
      };

      final response = await _api.post(ApiEndpoints.onTheWay, data: body);
      if (response.data != null && response.data['ok'] == true) {
        final newStatus = eventType == 'en_route' ? 'Job En Route' : 'Job Arrived';
        await updateLeadField(leadId, {'status': newStatus});
        return {
          'ok': true,
          'eta': response.data['eta'],
          'etaMinutes': response.data['etaMinutes'],
        };
      }
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> uploadPhotos(String leadId, List<XFile> images) async {
    if (images.isEmpty) return false;
    try {
      final formData = FormData();
      for (final img in images) {
        final bytes = await img.readAsBytes();
        formData.files.add(
          MapEntry(
            'photos',
            MultipartFile.fromBytes(bytes, filename: img.name),
          ),
        );
      }

      final response = await _api.post(
        ApiEndpoints.submissionPhotos(leadId),
        data: formData,
      );

      if (response.data != null && response.data['ok'] == true) {
        // Refresh this lead to show new photos
        final updatedLeadRes = await _api.get(ApiEndpoints.submissionDetail(leadId));
        if (updatedLeadRes.data != null && updatedLeadRes.data['item'] != null) {
          final updated = LeadModel.fromJson(updatedLeadRes.data['item']);
          final index = _leads.indexWhere((l) => l.id == leadId);
          if (index != -1) {
            _leads[index] = updated;
            notifyListeners();
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePhoto(String leadId, String publicId) async {
    try {
      final response = await _api.delete(
        ApiEndpoints.submissionPhotos(leadId),
        data: {'publicId': publicId},
      );

      if (response.data != null && response.data['ok'] == true) {
        final index = _leads.indexWhere((l) => l.id == leadId);
        if (index != -1) {
          final current = _leads[index];
          final updatedPhotos = current.photos.where((p) => p.publicId != publicId).toList();
          _leads[index] = current.copyWith(photos: updatedPhotos);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
