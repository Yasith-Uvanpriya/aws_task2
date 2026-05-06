import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        // Detects touch to navigate to the dashboard
        onTap: () => context.go('/dashboard'),
        behavior: HitTestBehavior.opaque, // Ensures the entire screen is tappable
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/my_pickle_logo.png',
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                },
              ),
              const SizedBox(height: 120),
              Container(
                width: 343,
                height: 30,
                alignment: Alignment.center,
                child: Text(
                  'Dil Pickle to-do',
                  style: GoogleFonts.gaegu(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}