import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aws_task2/screens/splash_screen.dart';
import 'package:aws_task2/screens/dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

// Defining the routing paths for the application
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Dil Pickle To-do',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      routerConfig: _router,
    );
  }
}