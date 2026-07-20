import 'package:flutter/material.dart';
import 'main_screen.dart';

class SuccessScreen extends StatefulWidget {
  final String itemId;
  final bool delivered;
  const SuccessScreen({super.key, required this.itemId, required this.delivered});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: widget.delivered ? const Color(0xFFE6F2FB) : const Color(0xFFFFEBEB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.delivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: widget.delivered ? const Color(0xFF1A7ABF) : const Color(0xFFD63031),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.delivered ? 'تم التسليم بنجاح' : 'تم تسجيل عدم التسليم',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF5C800), borderRadius: BorderRadius.circular(10)),
              child: Text(widget.itemId, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C), letterSpacing: 1.5)),
            ),
            const SizedBox(height: 24),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1A7ABF))),
          ]),
        ),
      ),
    );
  }
}
