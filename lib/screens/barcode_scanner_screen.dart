import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5C800),
        title: const Text('مسح الباركود', style: TextStyle(color: Color(0xFF1A3A5C))),
        iconTheme: const IconThemeData(color: Color(0xFF1A3A5C)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Color(0xFF1A3A5C)),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        // Scan frame overlay
        Center(
          child: Container(
            width: 260, height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF5C800), width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: const Center(
            child: Text(
              'وجّه الكاميرا نحو الباركود',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ]),
    );
  }
}
