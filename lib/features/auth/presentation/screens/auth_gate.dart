import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/config/supabase_runtime.dart';
import '../../../../core/theme/app_theme.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({required this.child, super.key});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Stream<AuthState>? _authStateChanges;

  @override
  void initState() {
    super.initState();
    if (SupabaseRuntime.isConfigured) {
      _authStateChanges = Supabase.instance.client.auth.onAuthStateChange;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseRuntime.isConfigured) {
      return widget.child;
    }

    return StreamBuilder<AuthState>(
      stream: _authStateChanges,
      builder: (BuildContext context, AsyncSnapshot<AuthState> snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const AuthScreen();
        }
        return widget.child;
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7FF),
      body: Stack(
        children: <Widget>[
          const _AuthPastelBackground(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    border: Border.all(color: const Color(0xFFC7DFFF)),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          _isSignUp ? '계정 만들기' : '로그인',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const Gap(8),
                        const Text('일기, 앨범, 캐릭터를 계정별로 저장합니다.'),
                        const Gap(18),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _authInputDecoration(
                            hintText: '이메일',
                            icon: Icons.mail_rounded,
                          ),
                        ),
                        const Gap(12),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _authInputDecoration(
                            hintText: '비밀번호',
                            icon: Icons.lock_rounded,
                          ),
                        ),
                        if (_isSignUp) ...<Widget>[
                          const Gap(12),
                          TextField(
                            controller: _nicknameController,
                            decoration: _authInputDecoration(
                              hintText: '닉네임',
                              icon: Icons.badge_rounded,
                            ),
                          ),
                        ],
                        const Gap(18),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _isSignUp
                                      ? Icons.person_add_rounded
                                      : Icons.login_rounded,
                                ),
                          label: Text(_isSignUp ? '회원가입' : '로그인'),
                        ),
                        const Gap(8),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() => _isSignUp = !_isSignUp);
                                },
                          child: Text(_isSignUp ? '이미 계정이 있어요' : '새 계정 만들기'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.length < 6) {
      _showMessage('이메일과 6자 이상 비밀번호를 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      if (_isSignUp) {
        final response = await client.auth.signUp(
          email: email,
          password: password,
          data: <String, dynamic>{
            'display_name': _nicknameController.text.trim(),
          },
        );
        final user = response.user;
        if (user != null) {
          await _upsertProfile(user, email);
        }
        if (response.session == null) {
          _showMessage('가입 확인 메일을 확인해 주세요.');
        }
      } else {
        final response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = response.user;
        if (user != null) {
          await _upsertProfile(user, email);
        }
      }
    } catch (error) {
      _showMessage('인증 실패: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _upsertProfile(User user, String email) async {
    final displayName = _nicknameController.text.trim().isNotEmpty
        ? _nicknameController.text.trim()
        : email.split('@').first;
    await Supabase.instance.client.from('profiles').upsert(<String, dynamic>{
      'id': user.id,
      'username': _safeUsername(email, user.id),
      'display_name': displayName,
      'avatar_url': user.userMetadata?['avatar_url']?.toString(),
      'is_public': true,
    });
  }

  String _safeUsername(String email, String userId) {
    final raw = email.split('@').first;
    final normalized = raw
        .replaceAll(RegExp('[^a-zA-Z0-9_]'), '_')
        .padRight(3, '_');
    final suffix = userId.replaceAll('-', '').substring(0, 6);
    final base = normalized.length > 16
        ? normalized.substring(0, 16)
        : normalized;
    return '${base}_$suffix';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AuthPastelBackground extends StatelessWidget {
  const _AuthPastelBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFEAF7FF),
            AppTheme.pastelBlue,
            AppTheme.pastelGreen,
          ],
        ),
      ),
    );
  }
}

InputDecoration _authInputDecoration({
  required String hintText,
  required IconData icon,
}) {
  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.76),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}
