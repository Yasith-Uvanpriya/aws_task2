import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      _showError('Could not load tasks');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addTask() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    try {
      final task = await TaskService.createTask(title);
      setState(() {
        _tasks.add(task);
        _controller.clear();
      });
    } catch (e) {
      _showError('Could not add task');
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

  // Soft delete — task disappears from UI, marked is_deleted in DynamoDB
  Future<void> _deleteTask(Task task) async {
    setState(() {
      _tasks.remove(task);
      _selectedTaskId = null;
    });
    try {
      await TaskService.deleteTask(task.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task deleted',
            style: GoogleFonts.gaegu(fontSize: 16, color: Colors.white),
          ),
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

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'edit task',
          style: GoogleFonts.gaegu(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFF383C),
          ),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: GoogleFonts.gaegu(fontSize: 20),
          decoration: InputDecoration(
            hintText: 'task name...',
            hintStyle: GoogleFonts.gaegu(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF34C759), width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF34C759), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel',
                style: GoogleFonts.gaegu(fontSize: 18, color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: Text('save',
                style: GoogleFonts.gaegu(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF34C759))),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != task.title) {
      final oldTitle = task.title;
      setState(() => task.title = result);
      try {
        await TaskService.updateTask(task.id, result);
      } catch (e) {
        setState(() => task.title = oldTitle);
        _showError('Could not update task');
      }
    }
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
              // Input row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'add new task',
                          style: GoogleFonts.gaegu(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
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
                          color: const Color(0xFF34C759),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add,
                        color: Color(0xFFFF383C), size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'task list',
                style: GoogleFonts.gaegu(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF383C),
                ),
              ),
              const SizedBox(height: 20),
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
                                final isSelected = _selectedTaskId == task.id;

                                return GestureDetector(
                                  onLongPress: () =>
                                      setState(() => _selectedTaskId = task.id),
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
                                      borderRadius: BorderRadius.circular(10),
                                      border: isSelected
                                          ? Border.all(
                                              color: const Color(0xFFFF383C)
                                                  .withOpacity(0.3),
                                              width: 1)
                                          : null,
                                    ),
                                    child: Row(
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
                                                color: const Color(0xFFFF383C),
                                                width: 1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: task.isDone
                                              ? const Icon(Icons.check,
                                                  size: 16, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 16),
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
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                        // Edit + Delete icons — only on long press
                                        if (isSelected) ...[
                                          GestureDetector(
                                            onTap: () => _editTask(task),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              margin: const EdgeInsets.only(
                                                  right: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF383C),
                                                borderRadius:
                                                    BorderRadius.circular(8),
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