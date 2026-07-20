import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/delivery_service.dart';
import '../services/constants.dart';
import '../services/daily_history_service.dart';
import 'success_screen.dart';

class NotDeliveredScreen extends StatefulWidget {
  final String itemId;
  final String office;
  const NotDeliveredScreen({super.key, required this.itemId, required this.office});
  @override
  State<NotDeliveredScreen> createState() => _NotDeliveredScreenState();
}

class _NotDeliveredScreenState extends State<NotDeliveredScreen> {
  late String _selectedOffice;
  String? _selectedReason;
  String _selectedMeasure = 'A';
  final _otherCtrl = TextEditingController();
  File? _failPhoto;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedOffice = kOfficeCodes.containsKey(widget.office)
        ? widget.office
        : kOfficeCodes.keys.first;
  }

  Future<void> _pickImage(ImageSource src) async {
    final picked = await ImagePicker().pickImage(source: src, imageQuality: 70);
    if (picked != null) setState(() => _failPhoto = File(picked.path));
  }

  Future<void> _submit() async {
    if (_selectedReason == null) { _snack('يرجى اختيار سبب عدم التسليم'); return; }
    if (_selectedReason == '59' && _otherCtrl.text.trim().isEmpty) { _snack('يرجى كتابة السبب'); return; }
    setState(() => _loading = true);

    final result = await DeliveryService.submitNonDelivery(
      itemId: widget.itemId,
      officeCd: _selectedOffice,
      reason: _selectedReason!,
      measure: _selectedMeasure,
      otherReason: _selectedReason == '59' ? _otherCtrl.text.trim() : null,
      failPhoto: _failPhoto,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success']) {
      await DailyHistoryService.addEntry(
        itemId: widget.itemId,
        officeCd: _selectedOffice,
        delivered: false,
        reason: kNonDeliveryReasons[_selectedReason] ?? '',
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SuccessScreen(itemId: widget.itemId, delivered: false)));
    } else {
      _snack(result['message'] ?? 'حدث خطأ');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD63031)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سبب عدم التسليم'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF1A3A5C), borderRadius: BorderRadius.circular(20)),
            child: Text(widget.itemId, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          // Reasons card
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: kNonDeliveryReasons.entries.map((e) {
                final selected = _selectedReason == e.key;
                return InkWell(
                  onTap: () => setState(() => _selectedReason = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFFFEBEB) : Colors.transparent,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFD63031) : const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text(e.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFFD63031)))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.value, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? const Color(0xFFD63031) : Colors.black87))),
                      if (selected) const Icon(Icons.check_circle_rounded, color: Color(0xFFD63031), size: 20),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedReason == '59') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('اكتب السبب', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(controller: _otherCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'أدخل السبب...')),
              ]),
            ),
          ],
          const SizedBox(height: 10),
          // Measure
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.checklist_rounded, color: Color(0xFF1A7ABF), size: 18), SizedBox(width: 6), Text('الإجراء المتخذ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey))]),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedMeasure,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                items: kMeasures.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                onChanged: (v) => setState(() => _selectedMeasure = v!),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          // Optional photo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.camera_alt_rounded, color: Color(0xFF1A7ABF), size: 18), SizedBox(width: 6), Text('صورة إثبات (اختياري)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey))]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1A7ABF)), label: const Text('كاميرا', style: TextStyle(color: Color(0xFF1A7ABF))))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF1A7ABF)), label: const Text('المعرض', style: TextStyle(color: Color(0xFF1A7ABF))))),
              ]),
              if (_failPhoto != null) ...[
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_failPhoto!, height: 120, width: double.infinity, fit: BoxFit.cover)),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded),
            label: Text(_loading ? 'جاري الإرسال...' : 'تأكيد عدم التسليم'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD63031)),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
