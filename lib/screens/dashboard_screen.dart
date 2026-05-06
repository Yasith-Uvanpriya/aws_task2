import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // List to store our tasks
  final List<String> _tasks = [];

  // Function to add a dummy task when plus is clicked
  void _addTask() {
    setState(() {
      _tasks.add('task 1');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      Container(
                        height: 3,
                        width: 247,
                        color: const Color(0xFF34C759),
                      ),
                    ],
                  ),
                ),
                // Wrapped the icon in an IconButton to make it clickable
                IconButton(
                  onPressed: _addTask,
                  icon: const Icon(
                    Icons.add,
                    color: Color(0xFFFF383C),
                    size: 30,
                  ),
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
            // Dynamic list of tasks based on the screenshot
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0, left: 20),
                    child: Row(
                      children: [
                        // Red rounded checkbox border
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFF383C), width: 1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 40),
                        // Task text
                        Text(
                          _tasks[index],
                          style: GoogleFonts.gaegu(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}