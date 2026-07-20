import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import '../services/delivery_service.dart';
import '../services/constants.dart';
import '../services/daily_history_service.dart';
import 'success_screen.dart';

class DeliveredScreen extends StatefulWidget {
  final String itemId;
  final String office;
  const DeliveredScreen({super.key, required this.itemId, required this.office});
  @override
  State<DeliveredScreen> createState() => _DeliveredScreenState();
}

class _DeliveredScreenState extends State<DeliveredScreen> {
  final _nameCtrl = TextEditingController();
  late String _selectedOffice;
  File? _proofImage;
  bool _loading = false;
  final _sigCtrl = SignatureController(penStrokeWidth: 2, penColor: Colors.black);

  @override
  void initState() {
    super.initState();
    // Use the user's office if it exists in the list, otherwise default to first item
    _selectedOffice = kOfficeCodes.containsKey(widget.office)
        ? widget.office
        : kOfficeCodes.keys.first;
  }

  Future<void> _pickImage(ImageSource src) async {
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 70);
    if (picked != null) setState(() => _proofImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) { _snack('يرجى إدخال اسم المستلم'); return; }
    if (_proofImage == null) { _snack('يرجى رفع صورة إثبات التسليم'); return; }
    setState(() => _loading = true);

    String? sigB64;
    if (_sigCtrl.isNotEmpty) {
      final bytes = await _sigCtrl.toPngBytes();
      if (bytes != null) sigB64 = base64Encode(bytes);
    }

    final result = await DeliveryService.submitDelivery(
      itemId: widget.itemId,
      officeCd: _selectedOffice,
      signatoryName: _nameCtrl.text.trim(),
      proofImage: _proofImage!,
      signatureBase64: sigB64,
    );
    setState(() => _loading = false);

    if (!mounted) return;
    if (result['success']) {
      await DailyHistoryService.addEntry(itemId: widget.itemId, officeCd: _selectedOffice, delivered: true);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuccessScreen(itemId: widget.itemId, delivered: true)));
    } else {
      _snack(result['message'] ?? 'حدث خطأ');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD63031)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل التسليم'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1A7ABF), borderRadius: BorderRadius.circular(20)),
            child: Text(widget.itemId, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          _card(title: 'بيانات التسليم', icon: Icons.store_rounded, children: [
            const Text('مكتب التسليم', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedOffice,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              items: kOfficeCodes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text('${e.value} (${e.key})'))).toList(),
              onChanged: (v) => setState(() => _selectedOffice = v!),
            ),
            const SizedBox(height: 12),
            const Text('اسم المستلم الفعلي', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'أدخل اسم المستلم...')),
          ]),
          const SizedBox(height: 10),
          _card(title: 'إثبات التسليم', icon: Icons.camera_alt_rounded, children: [
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1A7ABF)),
                label: const Text('كاميرا', style: TextStyle(color: Color(0xFF1A7ABF))),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF1A7ABF)),
                label: const Text('المعرض', style: TextStyle(color: Color(0xFF1A7ABF))),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
            ]),
            if (_proofImage != null) ...[
              const SizedBox(height: 10),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_proofImage!, height: 140, width: double.infinity, fit: BoxFit.cover)),
            ],
            const SizedBox(height: 12),
            const Text('توقيع المستلم (اختياري)', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1A7ABF), width: 1.5), borderRadius: BorderRadius.circular(10), color: const Color(0xFFE6F2FB)),
              child: Signature(controller: _sigCtrl, height: 110, backgroundColor: Colors.transparent),
            ),
            const SizedBox(height: 4),
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => _sigCtrl.clear(), child: const Text('مسح التوقيع', style: TextStyle(color: Color(0xFF1A7ABF))))),
          ]),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded),
            label: Text(_loading ? 'جاري الإرسال...' : 'تأكيد التسليم'),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _card({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: const Color(0xFF1A7ABF), size: 18), const SizedBox(width: 6), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey))]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}
