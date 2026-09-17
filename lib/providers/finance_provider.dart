import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';

class FinanceProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isProcessing = false;
  String? _errorMessage;

  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  Future<bool> sendInvoice({
    required String leadId,
    required double price,
    double gst = 10.0,
    String? service,
    String? description,
    String? extraWork,
    double? extraCharge,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? bsb,
    String? dueDate,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.sendInvoice,
        data: {
          'id': leadId,
          'price': price,
          'gst': gst,
          'service': ?service,
          'description': ?description,
          'extraWork': ?extraWork,
          'extraCharge': ?extraCharge,
          'bankName': ?bankName,
          'accountName': ?accountName,
          'accountNumber': ?accountNumber,
          'bsb': ?bsb,
          'dueDate': ?dueDate,
        },
      );

      _isProcessing = false;
      if (response.data != null && response.data['ok'] == true) {
        notifyListeners();
        return true;
      }
      _errorMessage = 'Could not send invoice.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPayment({
    required String leadId,
    required String type, // 'full' or 'partial'
    required double amount,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.patch(
        ApiEndpoints.submissionDetail(leadId),
        data: {
          'status': 'Payment Received',
          'paymentType': type,
          'amountPaid': amount,
          'invoiceStatus': type == 'full' ? 'Paid' : 'Partially Paid',
        },
      );

      _isProcessing = false;
      if (response.data != null && response.data['ok'] == true) {
        notifyListeners();
        return true;
      }
      _errorMessage = 'Failed to record payment.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> issueWarranty({
    required String leadId,
    required String customerName,
    required String address,
    String? jobNo,
    String? completionDate,
    String? expiryDate,
    String? authorisedBy,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.post(
        ApiEndpoints.sendWarranty,
        data: {
          'id': leadId,
          'warranty': {
            'customerName': customerName,
            'address': address,
            'jobNo': ?jobNo,
            'completionDate': ?completionDate,
            'expiryDate': ?expiryDate,
            'authorisedBy': ?authorisedBy,
            'provided': true,
          },
        },
      );

      _isProcessing = false;
      if (response.data != null && response.data['ok'] == true) {
        notifyListeners();
        return true;
      }
      _errorMessage = 'Could not issue warranty.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markCompleted(String leadId) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.patch(
        ApiEndpoints.submissionDetail(leadId),
        data: {'status': 'Completed'},
      );

      _isProcessing = false;
      if (response.data != null && response.data['ok'] == true) {
        notifyListeners();
        return true;
      }
      _errorMessage = 'Could not mark job as completed.';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isProcessing = false;
      notifyListeners();
      return false;
    }
  }
}
