import 'package:flutter/material.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The Icon has been replaced with a CircleAvatar displaying your image.
                const CircleAvatar(
                  radius: 140, // Controls the size of the circle
                  backgroundImage: AssetImage('assets/images/welcome.jpg'),
                  backgroundColor: Colors.transparent, // Prevents a solid color background if the image is loading
                ),
                const SizedBox(height: 24),
                const Text(
                  "Loan Manager",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Track loans, repayments, and customers with ease.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.indigo, backgroundColor: Colors.white, // Text color
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
