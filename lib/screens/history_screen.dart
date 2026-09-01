import 'package:flutter/material.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await HistoryService.getTodayHistory();
    setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final delivered = _items.where((i) => i['status'] == 'delivered').length;
    final failed = _items.where((i) => i['status'] == 'not_delivered').length;
    final express = _items.where((i) {
      final id = (i['item_id'] ?? '').toString().toUpperCase();
      return id.startsWith('DA') || id.startsWith('DB');
    }).length;
    final registered = _items.where((i) {
      final id = (i['item_id'] ?? '').toString().toUpperCase();
      return id.startsWith('RR') || id.startsWith('RA');
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('شحنات اليوم (${_items.length})'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A7ABF)))
          : Column(children: [
              // Summary bar
              if (_items.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFF5C800), borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Row(children: [
                      const Text('الإجمالي:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A3A5C))),
                      const SizedBox(width: 8),
                      Text('${_items.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A3A5C))),
                      const Spacer(),
                      _chip('$delivered مُسلَّم', const Color(0xFF1A7ABF)),
                      const SizedBox(width: 8),
                      _chip('$failed لم يُسلَّم', const Color(0xFFD63031)),
                    ]),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFD4A900)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A7ABF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(children: [
                          Text('$express', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A7ABF))),
                          const Text('البريد السريع', style: TextStyle(fontSize: 11, color: Color(0xFF1A3A5C))),
                          const Text('DA / DB', style: TextStyle(fontSize: 10, color: Color(0xFF1A3A5C))),
                        ]),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A5C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(children: [
                          Text('$registered', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                          const Text('البريد المسجل', style: TextStyle(fontSize: 11, color: Color(0xFF1A3A5C))),
                          const Text('RR / RA', style: TextStyle(fontSize: 10, color: Color(0xFF1A3A5C))),
                        ]),
                      )),
                    ]),
                  ]),
                ),
              Expanded(
                child: _items.isEmpty
                    ? const Center(child: Text('لا توجد شحنات اليوم بعد', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = _items[i];
                          final ok = item['status'] == 'delivered';
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundColor: ok ? const Color(0xFFE6F2FB) : const Color(0xFFFFEBEB),
                                child: Icon(ok ? Icons.check_rounded : Icons.close_rounded,
                                  color: ok ? const Color(0xFF1A7ABF) : const Color(0xFFD63031)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item['item_id'] ?? '',
                                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 3),
                                Text('${item['office_cd'] ?? ''} · ${item['time'] ?? ''}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (!ok && (item['reason'] ?? '').toString().isNotEmpty)
                                  Text(item['reason'], style: const TextStyle(fontSize: 12, color: Color(0xFFD63031))),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ok ? const Color(0xFFE6F2FB) : const Color(0xFFFFEBEB),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(ok ? 'تم' : 'لم يتم',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: ok ? const Color(0xFF1A7ABF) : const Color(0xFFD63031))),
                              ),
                            ]),
                          );
                        },
                      ),
              ),
            ]),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
