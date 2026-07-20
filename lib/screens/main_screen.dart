import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/daily_history_service.dart';
import 'login_screen.dart';
import 'delivered_screen.dart';
import 'not_delivered_screen.dart';
import 'history_screen.dart';
import 'barcode_scanner_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _itemCtrl = TextEditingController();
  String _username = '';
  String _office = '';
  List<Map<String, dynamic>> _lastItems = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.getUsername();
    final o = await AuthService.getOffice();
    final items = await DailyHistoryService.getTodayEntries();
    setState(() { _username = u; _office = o; _lastItems = items; });
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _itemCtrl.text = result.toUpperCase());
    }
  }

  void _go(bool delivered) {
    final id = _itemCtrl.text.trim().toUpperCase();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال رقم الشحنة أولاً')));
      return;
    }
    if (delivered) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveredScreen(itemId: id, office: _office))).then((_) => _load());
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => NotDeliveredScreen(itemId: id, office: _office))).then((_) => _load());
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final delivered = _lastItems.where((i) => i['status'] == 'delivered').length;
    final failed = _lastItems.where((i) => i['status'] == 'not_delivered').length;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/logo.jpg', fit: BoxFit.contain),
          ),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_username, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          Text(_office, style: const TextStyle(fontSize: 12, color: Color(0xFF1A3A5C))),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.history_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())).then((_) => _load())),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          // Today stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF5C800), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('اليوم', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
              const Spacer(),
              _statChip('$delivered', 'مُسلَّم'),
              const SizedBox(width: 20),
              _statChip('$failed', 'لم يُسلَّم', red: true),
            ]),
          ),
          const SizedBox(height: 12),
          // Item ID input
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF1A7ABF), borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('رقم الشحنة', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _itemCtrl,
                textDirection: TextDirection.ltr,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'monospace', letterSpacing: 1.5),
                decoration: InputDecoration(
                  hintText: 'EE000000000LY',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // Big action buttons
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => _go(true),
              child: Container(
                height: 86,
                decoration: BoxDecoration(color: const Color(0xFF1A7ABF), borderRadius: BorderRadius.circular(14)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 34),
                  SizedBox(height: 6),
                  Text('تم التسليم', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => _go(false),
              child: Container(
                height: 86,
                decoration: BoxDecoration(color: const Color(0xFFD63031), borderRadius: BorderRadius.circular(14)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.cancel_outlined, color: Colors.white, size: 34),
                  SizedBox(height: 6),
                  Text('لم يتسلّم', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 16),
          if (_lastItems.isNotEmpty) ...[
            const Align(alignment: Alignment.centerRight, child: Text('شحنات اليوم', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500))),
            const SizedBox(height: 8),
            Expanded(child: ListView.separated(
              itemCount: _lastItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = _lastItems[i];
                final ok = item['status'] == 'delivered';
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: ok ? const Color(0xFFE6F2FB) : const Color(0xFFFFEBEB),
                      child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, color: ok ? const Color(0xFF1A7ABF) : const Color(0xFFD63031)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item['item_id'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      Text(item['office_cd'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ok ? const Color(0xFFE6F2FB) : const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(ok ? 'تم التسليم' : 'لم يتم', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ok ? const Color(0xFF1A7ABF) : const Color(0xFFD63031))),
                    ),
                  ]),
                );
              },
            )),
          ],
        ]),
      ),
    );
  }

  Widget _statChip(String num, String label, {bool red = false}) {
    return Column(children: [
      Text(num, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: red ? const Color(0xFFD63031) : const Color(0xFF1A3A5C))),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1A3A5C))),
    ]);
  }
}
