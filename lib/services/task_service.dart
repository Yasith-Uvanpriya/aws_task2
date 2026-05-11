import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String _baseUrl =
    'https://o8gjp7q6nj.execute-api.us-east-1.amazonaws.com/prod';

class Task {
  final String id;
  String title;
  bool isDone;
  final String createdAt;

  Task({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        isDone: json['is_done'] ?? false,
        createdAt: json['created_at'],
      );
}

class TaskService {
  // Fetch active (non-deleted) tasks
  static Future<List<Task>> getTasks() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/tasks'));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Task.fromJson(e)).toList();
      }
      throw Exception('GET failed: ${res.statusCode} ${res.body}');
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      rethrow;
    } catch (e) {
      print('❌ ERROR: $e');
      rethrow;
    }
  }

  // Create a new task
  static Future<Task> createTask(String title) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title}),
      );
      if (res.statusCode == 201) return Task.fromJson(jsonDecode(res.body));
      throw Exception('POST failed: ${res.statusCode} ${res.body}');
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      rethrow;
    } catch (e) {
      print('❌ ERROR: $e');
      rethrow;
    }
  }

  // Toggle is_done
  static Future<void> toggleTask(String id, bool isDone) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_done': isDone}),
      );
    } catch (e) {
      print('❌ ERROR: $e');
      rethrow;
    }
  }

  // Update task title
  static Future<void> updateTask(String id, String newTitle) async {
    try {
      await http.patch(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': newTitle}),
      );
    } catch (e) {
      print('❌ ERROR: $e');
      rethrow;
    }
  }

  // Soft delete — sets is_deleted: true in DynamoDB, disappears from UI
  static Future<void> deleteTask(String id) async {
    try {
      await http.delete(Uri.parse('$_baseUrl/tasks/$id'));
    } catch (e) {
      print('❌ ERROR: $e');
      rethrow;
    }
  }
}