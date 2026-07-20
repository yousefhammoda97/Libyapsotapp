import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final creds = await AuthService.getSavedCredentials();
    if (creds != null) {
      setState(() {
        _userCtrl.text = creds['username'] ?? '';
        _passCtrl.text = creds['password'] ?? '';
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _snack('يرجى إدخال اسم المستخدم وكلمة المرور');
      return;
    }
    setState(() => _loading = true);
    final result = await AuthService.login(_userCtrl.text.trim(), _passCtrl.text, rememberMe: _rememberMe);
    setState(() => _loading = false);
    if (result['success']) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      _snack(result['message'] ?? 'فشل تسجيل الدخول');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD63031)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Yellow hero header with logo
          Container(
            width: double.infinity,
            color: const Color(0xFFF5C800),
            padding: const EdgeInsets.only(top: 70, bottom: 32),
            child: Column(children: [
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/logo.jpg', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 14),
              const Text('بريد ليبيا', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
              const SizedBox(height: 4),
              const Text('تطبيق عمليات التوصيل', style: TextStyle(fontSize: 14, color: Color(0xFF1A3A5C))),
            ]),
          ),
          // White form
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 8),
                const Text('اسم المستخدم', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(controller: _userCtrl, textDirection: TextDirection.ltr, decoration: const InputDecoration(hintText: 'أدخل اسم المستخدم')),
                const SizedBox(height: 14),
                const Text('كلمة المرور', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  SizedBox(
                    height: 24, width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: const Color(0xFF1A7ABF),
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: const Text('تذكرني', style: TextStyle(fontSize: 14, color: Color(0xFF1A3A5C))),
                  ),
                ]),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('تسجيل الدخول'),
                ),
                const Spacer(),
                const Center(child: Text('للاستخدام الداخلي — موظفو التوصيل فقط', style: TextStyle(fontSize: 12, color: Colors.grey))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
