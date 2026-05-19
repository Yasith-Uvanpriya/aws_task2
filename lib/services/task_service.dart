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
  String? imageUrl;

  Task({
    required this.id,
    required this.title,
    required this.isDone,
    required this.createdAt,
    this.imageUrl,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      return Task(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        isDone: json['is_done'] == true,
        createdAt: json['created_at']?.toString() ?? '',
        // safely handle null, missing, or non-string image_url
        imageUrl: (json['image_url'] != null && json['image_url'] is String)
            ? json['image_url'] as String
            : null,
      );
    } catch (e) {
      print('❌ Task.fromJson error: $e — json: $json');
      rethrow;
    }
  }
}

class TaskService {
  // ── Fetch active tasks ────────────────────────────────────────────────────
  static Future<List<Task>> getTasks() async {
    try {
      print('🔵 GET: $_baseUrl/tasks');
      final res = await http.get(Uri.parse('$_baseUrl/tasks'));
      print('✅ STATUS: ${res.statusCode}');
      print('✅ BODY: ${res.body}');

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        final tasks = <Task>[];
        for (final item in data) {
          try {
            tasks.add(Task.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            print('❌ Skipping task due to parse error: $e');
          }
        }
        return tasks;
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

  // ── Get pre-signed S3 upload URL ──────────────────────────────────────────
  static Future<Map<String, String>> getUploadUrl(
      String filename, String contentType) async {
    try {
      print('🔵 GET upload-url: filename=$filename');
      final uri = Uri.parse('$_baseUrl/upload-url').replace(
        queryParameters: {
          'filename': filename,
          'contentType': contentType,
        },
      );
      final res = await http.get(uri);
      print('✅ STATUS: ${res.statusCode}');
      print('✅ BODY: ${res.body}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'uploadUrl': data['uploadUrl'],
          'imageUrl': data['imageUrl'],
          'key': data['key'],
        };
      }
      throw Exception('Failed to get upload URL: ${res.statusCode} ${res.body}');
    } catch (e) {
      print('❌ ERROR getUploadUrl: $e');
      rethrow;
    }
  }

  // ── Upload image directly to S3 ───────────────────────────────────────────
  static Future<void> uploadImageToS3(
      String uploadUrl, File imageFile, String contentType) async {
    try {
      print('🔵 Uploading to S3...');
      final bytes = await imageFile.readAsBytes();
      final res = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': contentType},
        body: bytes,
      );
      print('✅ S3 Upload STATUS: ${res.statusCode}');
      if (res.statusCode != 200) {
        throw Exception('S3 upload failed: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      print('❌ S3 Upload ERROR: $e');
      rethrow;
    }
  }

  // ── Create a new task ─────────────────────────────────────────────────────
  static Future<Task> createTask(String title, {String? imageUrl}) async {
    try {
      print('🔵 POST: title=$title imageUrl=$imageUrl');
      final res = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          if (imageUrl != null) 'image_url': imageUrl,
        }),
      );
      print('✅ STATUS: ${res.statusCode}');
      print('✅ BODY: ${res.body}');
      if (res.statusCode == 201) {
        return Task.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw Exception('POST failed: ${res.statusCode} ${res.body}');
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      rethrow;
    } catch (e) {
      print('❌ ERROR: $e');
      rethrow;
    }
  }

  // ── Toggle is_done ────────────────────────────────────────────────────────
  static Future<void> toggleTask(String id, bool isDone) async {
    try {
      print('🔵 PATCH toggle: $id → $isDone');
      final res = await http.patch(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_done': isDone}),
      );
      print('✅ STATUS: ${res.statusCode}');
    } catch (e) {
      print('❌ ERROR: $e');
      rethrow;
    }
  }

  // ── Update task title and/or image ────────────────────────────────────────
  static Future<void> updateTask(String id,
      {String? title, String? imageUrl}) async {
    try {
      final Map<String, dynamic> payload = {};
      if (title != null && title.isNotEmpty) payload['title'] = title;
      if (imageUrl != null) payload['image_url'] = imageUrl;

      print('🔵 PATCH update: $id payload=$payload');
      final res = await http.patch(
        Uri.parse('$_baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      print('✅ STATUS: ${res.statusCode}');
    } catch (e) {
      print('❌ ERROR: $e');
      rethrow;
    }
  }

  // ── Soft delete ───────────────────────────────────────────────────────────
  static Future<void> deleteTask(String id) async {
    try {
      print('🔵 DELETE: $id');
      final res = await http.delete(Uri.parse('$_baseUrl/tasks/$id'));
      print('✅ STATUS: ${res.statusCode}');
    } catch (e) {
      print('❌ ERROR: $e');
      rethrow;
    }
  }
}