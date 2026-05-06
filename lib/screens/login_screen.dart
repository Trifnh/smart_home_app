import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/firebase_providers.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool register}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(firebaseServiceProvider);
      if (register) {
        await service.signUpWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await service.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      }
      if (!mounted) return;
      // Firebase authStateChanges refreshes Shell via MyApp/_AuthSwitcher.
    } catch (e) {
      setState(() => _error = _mapAuthError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(String raw) {
    final err = raw.toLowerCase();
    if (err.contains('configuration-not-found')) {
      return 'Firebase Auth chua duoc cau hinh. Vao Firebase Console > Authentication > Sign-in method > Enable Email/Password.';
    }
    if (err.contains('user-not-found')) return 'Khong tim thay tai khoan.';
    if (err.contains('wrong-password') || err.contains('invalid-credential')) {
      return 'Sai email hoac mat khau.';
    }
    if (err.contains('email-already-in-use')) return 'Email da ton tai.';
    if (err.contains('invalid-email')) return 'Email khong hop le.';
    return raw.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgDeep, Color(0xFF0F172A), Color(0xFF134E4A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                color: AppTheme.bgCard.withValues(alpha: 0.94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.houseboat_rounded,
                          size: 40,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Smart AIoT Home',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Group 12 - FAST - Hải Trình - Đình Khánh',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                            labelText: 'Email',
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Email không hợp lệ'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                            labelText: 'Mật khẩu',
                          ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Mật khẩu tối thiểu 6 ký tự'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.danger),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _loading
                                ? null
                                : () => _submit(register: false),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              backgroundColor: AppTheme.accentDim,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Đăng nhập'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _loading
                                ? null
                                : () => _submit(register: true),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                            ),
                            child: const Text('Đăng ký'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
