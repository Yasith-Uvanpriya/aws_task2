import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aws_task2/services/task_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Task> _tasks = [];
  bool _loading = true;
  final TextEditingController _controller = TextEditingController();
  String? _selectedTaskId;

  File? _pickedImage;
  String? _pickedImageName;
  String? _pickedImageContentType;
  bool _uploadingImage = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    try {
      final tasks = await TaskService.getTasks();
      setState(() => _tasks = tasks);
    } catch (e) {
      _showError('Could not load tasks: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    final XFile? picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
        _pickedImageName = picked.name;
        _pickedImageContentType =
            picked.name.endsWith('.png') ? 'image/png' : 'image/jpeg';
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('add image',
                style: GoogleFonts.gaegu(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _imageSourceButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(fromCamera: true);
                  },
                ),
                _imageSourceButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(fromCamera: false);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF383C).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFF383C).withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF383C), size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.gaegu(
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImageToS3(File imageFile, String contentType) async {
    try {
      final filename =
          'task_${DateTime.now().millisecondsSinceEpoch}.${contentType == 'image/png' ? 'png' : 'jpg'}';
      final urlData = await TaskService.getUploadUrl(filename, contentType);
      await TaskService.uploadImageToS3(
          urlData['uploadUrl']!, imageFile, contentType);
      return urlData['imageUrl'];
    } catch (e) {
      _showError('Could not upload image');
      return null;
    }
  }

  Future<void> _addTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() => _uploadingImage = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImageToS3(
            _pickedImage!, _pickedImageContentType ?? 'image/jpeg');
      }
      final task = await TaskService.createTask(title, imageUrl: imageUrl);
      setState(() {
        _tasks.add(task);
        _controller.clear();
        _pickedImage = null;
        _pickedImageName = null;
        _pickedImageContentType = null;
      });
    } catch (e) {
      _showError('Could not add task');
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _toggleTask(Task task) async {
    if (_selectedTaskId != null) {
      setState(() => _selectedTaskId = null);
      return;
    }
    final newVal = !task.isDone;
    setState(() => task.isDone = newVal);
    try {
      await TaskService.toggleTask(task.id, newVal);
    } catch (e) {
      setState(() => task.isDone = !newVal);
      _showError('Could not update task');
    }
  }

  Future<void> _deleteTask(Task task) async {
    setState(() {
      _tasks.remove(task);
      _selectedTaskId = null;
    });
    try {
      await TaskService.deleteTask(task.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task deleted',
              style: GoogleFonts.gaegu(fontSize: 16, color: Colors.white)),
          backgroundColor: const Color(0xFFFF383C),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _tasks.add(task));
      _showError('Could not delete task');
    }
  }

  Future<void> _editTask(Task task) async {
    setState(() => _selectedTaskId = null);
    final editController = TextEditingController(text: task.title);
    File? newImage;
    String? newImageName;
    String? newContentType;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('edit task',
              style: GoogleFonts.gaegu(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF383C))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                autofocus: true,
                style: GoogleFonts.gaegu(fontSize: 20),
                decoration: InputDecoration(
                  hintText: 'task name...',
                  hintStyle: GoogleFonts.gaegu(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF34C759), width: 2),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFF34C759), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Image picker row in edit dialog
              GestureDetector(
                onTap: () async {
                  final XFile? picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 75,
                    maxWidth: 1200,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      newImage = File(picked.path);
                      newImageName = picked.name;
                      newContentType = picked.name.endsWith('.png')
                          ? 'image/png'
                          : 'image/jpeg';
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        newImageName != null
                            ? _truncateFilename(newImageName!)
                            : task.imageUrl != null
                                ? _truncateFilename(
                                    task.imageUrl!.split('/').last)
                                : 'add image',
                        style: GoogleFonts.gaegu(
                            fontSize: 15,
                            color: newImageName != null
                                ? const Color(0xFF34C759)
                                : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel',
                  style:
                      GoogleFonts.gaegu(fontSize: 18, color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('save',
                  style: GoogleFonts.gaegu(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF34C759))),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      final newTitle = editController.text.trim();
      String? uploadedUrl;
      if (newImage != null) {
        uploadedUrl = await _uploadImageToS3(
            newImage!, newContentType ?? 'image/jpeg');
      }
      final oldTitle = task.title;
      final oldImageUrl = task.imageUrl;
      if (newTitle.isNotEmpty) setState(() => task.title = newTitle);
      if (uploadedUrl != null) setState(() => task.imageUrl = uploadedUrl);
      try {
        await TaskService.updateTask(task.id,
            title: newTitle.isNotEmpty ? newTitle : null,
            imageUrl: uploadedUrl);
      } catch (e) {
        setState(() {
          task.title = oldTitle;
          task.imageUrl = oldImageUrl;
        });
        _showError('Could not update task');
      }
    });
  }

  // ── Full screen image viewer ──────────────────────────────────────────────
  void _viewFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image,
                    color: Colors.white, size: 60),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _truncateFilename(String name) {
    final clean = name.contains('-') && name.contains('/')
        ? name.split('/').last.replaceFirst(RegExp(r'^[a-f0-9\-]+\-'), '')
        : name;
    if (clean.length <= 20) return clean;
    final ext = clean.contains('.') ? '.${clean.split('.').last}' : '';
    return '${clean.substring(0, 16)}...$ext';
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.gaegu(fontSize: 16))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_selectedTaskId != null) setState(() => _selectedTaskId = null);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 66),
              Text(
                'My silly little tasks',
                style: GoogleFonts.gaegu(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),

              // ── Add task input row ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('add new task',
                            style: GoogleFonts.gaegu(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _controller,
                          style: GoogleFonts.gaegu(fontSize: 18),
                          decoration: InputDecoration(
                            hintText: 'task name...',
                            hintStyle: GoogleFonts.gaegu(color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addTask(),
                        ),
                        Container(
                            height: 3,
                            width: 247,
                            color: const Color(0xFF34C759)),
                      ],
                    ),
                  ),
                  // Image picker icon button
                  IconButton(
                    onPressed: _showImageSourceDialog,
                    icon: Icon(
                      _pickedImage != null
                          ? Icons.image
                          : Icons.add_photo_alternate_outlined,
                      color: _pickedImage != null
                          ? const Color(0xFF34C759)
                          : Colors.grey,
                      size: 28,
                    ),
                  ),
                  // Add task button
                  _uploadingImage
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFFF383C)),
                        )
                      : IconButton(
                          onPressed: _addTask,
                          icon: const Icon(Icons.add,
                              color: Color(0xFFFF383C), size: 30),
                        ),
                ],
              ),

              // ── Filename only (no image preview) after picking ────────────
              if (_pickedImage != null && _pickedImageName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Row(
                    children: [
                      // Filename chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34C759).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  const Color(0xFF34C759).withOpacity(0.4),
                              width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.image_outlined,
                                color: Color(0xFF34C759), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _truncateFilename(_pickedImageName!),
                              style: GoogleFonts.gaegu(
                                  fontSize: 14,
                                  color: const Color(0xFF34C759),
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Remove image
                      GestureDetector(
                        onTap: () => setState(() {
                          _pickedImage = null;
                          _pickedImageName = null;
                          _pickedImageContentType = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.grey, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              Text('task list',
                  style: GoogleFonts.gaegu(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF383C))),
              const SizedBox(height: 20),

              // ── Task list ─────────────────────────────────────────────────
              _loading
                  ? const CircularProgressIndicator(color: Color(0xFFFF383C))
                  : Expanded(
                      child: _tasks.isEmpty
                          ? Center(
                              child: Text('no tasks yet!',
                                  style: GoogleFonts.gaegu(
                                      fontSize: 20, color: Colors.grey)),
                            )
                          : ListView.builder(
                              itemCount: _tasks.length,
                              itemBuilder: (context, index) {
                                final task = _tasks[index];
                                final isSelected =
                                    _selectedTaskId == task.id;

                                return GestureDetector(
                                  onLongPress: () => setState(
                                      () => _selectedTaskId = task.id),
                                  onTap: () => _toggleTask(task),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(
                                        bottom: 15.0, left: 10, right: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFF383C)
                                              .withOpacity(0.07)
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: isSelected
                                          ? Border.all(
                                              color: const Color(0xFFFF383C)
                                                  .withOpacity(0.3),
                                              width: 1)
                                          : null,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Checkbox
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: task.isDone
                                                ? const Color(0xFF34C759)
                                                : Colors.transparent,
                                            border: Border.all(
                                                color:
                                                    const Color(0xFFFF383C),
                                                width: 1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: task.isDone
                                              ? const Icon(Icons.check,
                                                  size: 16,
                                                  color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 10),

                                        // ── Small thumbnail BEFORE task title ──
                                        if (task.imageUrl != null)
                                          GestureDetector(
                                            onTap: () => _viewFullImage(
                                                task.imageUrl!),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  right: 10),
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.grey
                                                        .shade300,
                                                    width: 1),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                                child: Image.network(
                                                  task.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context,
                                                      child, progress) {
                                                    if (progress == null)
                                                      return child;
                                                    return Container(
                                                      color: Colors
                                                          .grey.shade100,
                                                      child: const Center(
                                                        child: SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Color(
                                                                0xFFFF383C),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          Container(
                                                    color:
                                                        Colors.grey.shade100,
                                                    child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.grey,
                                                        size: 20),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                        // Task title
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: GoogleFonts.gaegu(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: task.isDone
                                                  ? Colors.grey
                                                  : Colors.black,
                                              decoration: task.isDone
                                                  ? TextDecoration
                                                      .lineThrough
                                                  : TextDecoration.none,
                                            ),
                                          ),
                                        ),

                                        // Edit + Delete on long press
                                        if (isSelected) ...[
                                          GestureDetector(
                                            onTap: () => _editTask(task),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(8),
                                              margin: const EdgeInsets.only(
                                                  right: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                              ),
                                              child: const Icon(
                                                  Icons.edit_outlined,
                                                  color: Colors.black54,
                                                  size: 22),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _deleteTask(task),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color:
                                                    const Color(0xFFFF383C),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                              ),
                                              child: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.white,
                                                  size: 22),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}