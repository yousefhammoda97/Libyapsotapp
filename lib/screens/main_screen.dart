import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
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
  String _office = AuthService.defaultOffice;
  List<Map<String, dynamic>> _todayItems = [];
  Map<String, dynamic> _monthlyStats = {
    'express_count': 0, 'registered_count': 0, 'other_count': 0, 'total': 0, 'year_month': ''
  };
  bool _loadingHistory = false;
  bool _checkingDuplicate = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.getUsername();
    setState(() { _username = u; _loadingHistory = true; });
    final results = await Future.wait([
      HistoryService.getTodayHistory(),
      HistoryService.getMonthlyStats(),
    ]);
    setState(() {
      _todayItems = results[0] as List<Map<String, dynamic>>;
      _monthlyStats = results[1] as Map<String, dynamic>;
      _loadingHistory = false;
    });
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context, MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()));
    if (result != null && result.isNotEmpty) {
      setState(() => _itemCtrl.text = result.toUpperCase());
    }
  }

  Future<void> _go(bool delivered) async {
    final id = _itemCtrl.text.trim().toUpperCase();
    if (id.isEmpty) { _snack('يرجى إدخال رقم الشحنة أولاً'); return; }

    setState(() => _checkingDuplicate = true);
    final check = await HistoryService.checkDuplicate(id);
    setState(() => _checkingDuplicate = false);

    if (check['already_exists'] == true) {
      _showDuplicateDialog(check['message'] ?? 'تم تسجيل هذه البعيثة مسبقاً اليوم', check['status']);
      return;
    }

    if (delivered) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => DeliveredScreen(itemId: id, office: _office))).then((_) => _load());
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => NotDeliveredScreen(itemId: id, office: _office))).then((_) => _load());
    }
  }

  void _showDuplicateDialog(String message, String status) {
    final isDelivered = status == 'delivered';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          isDelivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isDelivered ? const Color(0xFF1A7ABF) : const Color(0xFFD63031),
          size: 48,
        ),
        title: const Text('بعيثة مسجلة مسبقاً', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً', style: TextStyle(color: Color(0xFF1A7ABF), fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD63031)));

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  int get _deliveredCount => _todayItems.where((i) => i['status'] == 'delivered').length;
  int get _failedCount => _todayItems.where((i) => i['status'] == 'not_delivered').length;

  String _monthLabel() {
    final ym = _monthlyStats['year_month']?.toString() ?? '';
    if (ym.isEmpty) return 'هذا الشهر';
    final months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    try {
      final parts = ym.split('-');
      final m = int.parse(parts[1]);
      return months[m];
    } catch (_) { return 'هذا الشهر'; }
  }

  @override
  Widget build(BuildContext context) {
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
          const Text('البريد المركزي', style: TextStyle(fontSize: 12, color: Color(0xFF1A3A5C))),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistoryScreen())).then((_) => _load())),
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout),
        ],
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [

          // ── MONTHLY STATS ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text('إجمالي ${_monthLabel()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                Text('${_monthlyStats['total']} بعيثة',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _monthlyCard('البريد السريع', 'DA / DB',
                  _monthlyStats['express_count'] ?? 0, const Color(0xFFF5C800), const Color(0xFF1A3A5C))),
                const SizedBox(width: 8),
                Expanded(child: _monthlyCard('البريد المسجل', 'RR / RA',
                  _monthlyStats['registered_count'] ?? 0, const Color(0xFF1A7ABF), Colors.white)),
                const SizedBox(width: 8),
                Expanded(child: _monthlyCard('أخرى', 'غير ذلك',
                  _monthlyStats['other_count'] ?? 0, Colors.white24, Colors.white)),
              ]),
            ]),
          ),
          const SizedBox(height: 10),

          // ── TODAY STATS ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFFF5C800), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('اليوم', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C), fontSize: 13)),
              const Spacer(),
              _statChip('$_deliveredCount', 'مُسلَّم'),
              const SizedBox(width: 16),
              _statChip('$_failedCount', 'لم يُسلَّم', red: true),
              const SizedBox(width: 16),
              _statChip('${_todayItems.length}', 'الإجمالي'),
            ]),
          ),
          const SizedBox(height: 10),

          // ── ITEM ID INPUT ──────────────────────────────────
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
          const SizedBox(height: 10),

          // ── ACTION BUTTONS ─────────────────────────────────
          _checkingDuplicate
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF1A7ABF)))
              : Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => _go(true),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(color: const Color(0xFF1A7ABF), borderRadius: BorderRadius.circular(14)),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 32),
                        SizedBox(height: 4),
                        Text('تم التسليم', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: GestureDetector(
                    onTap: () => _go(false),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(color: const Color(0xFFD63031), borderRadius: BorderRadius.circular(14)),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.cancel_outlined, color: Colors.white, size: 32),
                        SizedBox(height: 4),
                        Text('لم يتسلّم', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  )),
                ]),
          const SizedBox(height: 12),

          // ── TODAY'S LIST ───────────────────────────────────
          Row(children: [
            const Text('شحنات اليوم', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (_loadingHistory)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A7ABF)))
            else
              IconButton(icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.grey),
                onPressed: _load, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ]),
          const SizedBox(height: 6),
          Expanded(
            child: _todayItems.isEmpty
                ? const Center(child: Text('لا توجد شحنات اليوم بعد', style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    itemCount: _todayItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _todayItems[i];
                      final ok = item['status'] == 'delivered';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                        child: Row(children: [
                          CircleAvatar(
                            backgroundColor: ok ? const Color(0xFFE6F2FB) : const Color(0xFFFFEBEB),
                            child: Icon(ok ? Icons.check_rounded : Icons.close_rounded,
                              color: ok ? const Color(0xFF1A7ABF) : const Color(0xFFD63031)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item['item_id'] ?? '',
                              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                            Text('${item['office_cd'] ?? ''} · ${item['time'] ?? ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ok ? const Color(0xFFE6F2FB) : const Color(0xFFFFEBEB),
                              borderRadius: BorderRadius.circular(20)),
                            child: Text(ok ? 'تم التسليم' : 'لم يتم',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: ok ? const Color(0xFF1A7ABF) : const Color(0xFFD63031))),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _monthlyCard(String title, String subtitle, dynamic count, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 2),
        Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor), textAlign: TextAlign.center),
        Text(subtitle, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7)), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _statChip(String num, String label, {bool red = false}) {
    return Column(children: [
      Text(num, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
        color: red ? const Color(0xFFD63031) : const Color(0xFF1A3A5C))),
      Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1A3A5C))),
    ]);
  }
}
