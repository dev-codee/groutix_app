import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/task_model.dart';

class TasksProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<CrmTask> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CrmTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingCount => _tasks.where((t) => !t.done).length;

  Future<void> fetchTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiEndpoints.tasks);
      final data = response.data;
      if (data != null && data['items'] is List) {
        _tasks = (data['items'] as List)
            .map((item) => CrmTask.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTask(String text) async {
    if (text.trim().isEmpty) return false;
    try {
      final response = await _api.post(
        ApiEndpoints.tasks,
        data: {'text': text.trim()},
      );

      final data = response.data;
      if (data != null && data['item'] != null) {
        _tasks.insert(0, CrmTask.fromJson(data['item']));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTask(String id, bool done) async {
    try {
      final response = await _api.patch(
        ApiEndpoints.taskDetail(id),
        data: {'done': done},
      );

      if (response.data != null && response.data['ok'] == true) {
        final index = _tasks.indexWhere((t) => t.id == id);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(done: done);
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

  Future<bool> deleteTask(String id) async {
    try {
      final response = await _api.delete(ApiEndpoints.taskDetail(id));
      if (response.data != null && response.data['ok'] == true) {
        _tasks.removeWhere((t) => t.id == id);
        notifyListeners();
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
