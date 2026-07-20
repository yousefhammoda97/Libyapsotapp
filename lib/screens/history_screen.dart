import 'package:flutter/material.dart';
import '../services/daily_history_service.dart';

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
    final items = await DailyHistoryService.getTodayEntries();
    setState(() { _items = items; _loading = false; });
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شحنات اليوم'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A7ABF)))
          : _items.isEmpty
              ? const Center(child: Text('لا توجد شحنات اليوم بعد', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
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
                          child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, color: ok ? const Color(0xFF1A7ABF) : const Color(0xFFD63031)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['item_id'] ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text('${item['office_cd'] ?? ''} · ${_formatTime(item['time'] ?? '')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          if (!ok && (item['reason'] ?? '').toString().isNotEmpty)
                            Text(item['reason'], style: const TextStyle(fontSize: 12, color: Color(0xFFD63031))),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ok ? const Color(0xFFE6F2FB) : const Color(0xFFFFEBEB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(ok ? 'تم' : 'لم يتم', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ok ? const Color(0xFF1A7ABF) : const Color(0xFFD63031))),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }
}
