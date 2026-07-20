import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    // Small minimum display time so the splash doesn't flash too quickly
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => isLoggedIn ? const MainScreen() : const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5C800),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/logo.jpg', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 20),
          const Text('بريد ليبيا', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 6),
          const Text('تطبيق عمليات التوصيل', style: TextStyle(fontSize: 13, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 36),
          const SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1A7ABF)),
          ),
        ]),
      ),
    );
  }
}
