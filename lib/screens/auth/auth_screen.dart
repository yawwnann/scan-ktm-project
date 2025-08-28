import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import '../navigation/main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscurePass2 = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;

      if (_isLogin) {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // Register user
        final credential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Update display name (non-blocking)
        try {
          await credential.user?.updateDisplayName(_nameController.text.trim());
        } catch (_) {}

        // Save profile to Realtime Database (non-blocking)
        try {
          final uid = credential.user!.uid;
          final db = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
                'https://scan-ktm-default-rtdb.asia-southeast1.firebasedatabase.app',
          );
          await db.ref('users/$uid').set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Registrasi berhasil, tetapi gagal menyimpan profil: $e',
                ),
              ),
            );
          }
        }
      }

      if (!mounted) return;
      // Navigate to main after success
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan. Coba lagi.';
      switch (e.code) {
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          message = 'Akun dinonaktifkan.';
          break;
        case 'user-not-found':
          message = 'Pengguna tidak ditemukan.';
          break;
        case 'wrong-password':
          message = 'Password salah.';
          break;
        case 'email-already-in-use':
          message = 'Email sudah terdaftar.';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah (min. 6 karakter).';
          break;
        case 'operation-not-allowed':
          message =
              'Metode email/password belum diaktifkan di Firebase Console.';
          break;
        case 'network-request-failed':
          message = 'Jaringan bermasalah. Periksa koneksi internet Anda.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan. Coba lagi nanti.';
          break;
        default:
          message = e.message ?? message;
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan email terlebih dahulu.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link reset password dikirim ke email.'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal kirim reset: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: color,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with Logo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Image.asset('assets/logo.png'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ID Recognizer & Quickscan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Masuk ke akun Anda' : 'Buat akun baru',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Toggle Mode - Clean Design
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isLogin = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isLogin
                                          ? color
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Masuk',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _isLogin
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _isLogin = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !_isLogin
                                          ? color
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Daftar',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: !_isLogin
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: _buildPrefixIcon(
                                Icons.person_outline,
                              ),
                              border: _border(),
                              enabledBorder: _border(),
                              focusedBorder: _focusedBorder(color),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: _buildPrefixIcon(Icons.email_outlined),
                            border: _border(),
                            enabledBorder: _border(),
                            focusedBorder: _focusedBorder(color),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Email wajib diisi';
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePass,
                          textInputAction: _isLogin
                              ? TextInputAction.done
                              : TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: _buildPrefixIcon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                            border: _border(),
                            enabledBorder: _border(),
                            focusedBorder: _focusedBorder(color),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'Minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePass2,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi Password',
                              prefixIcon: _buildPrefixIcon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass2
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePass2 = !_obscurePass2,
                                ),
                              ),
                              border: _border(),
                              enabledBorder: _border(),
                              focusedBorder: _focusedBorder(color),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Konfirmasi password wajib diisi';
                              }
                              if (v != _passwordController.text) {
                                return 'Password tidak sama';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: Text(
                                'Lupa Password?',
                                style: TextStyle(color: color),
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            icon: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _isLogin ? Icons.login : Icons.person_add,
                                  ),
                            label: Text(_isLogin ? 'Masuk' : 'Daftar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Bottom text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Belum punya akun?'
                                  : 'Sudah punya akun?',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin ? 'Daftar' : 'Masuk',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Dynamic bottom spacing - less for login, more for register
                        SizedBox(height: _isLogin ? 40 : 60),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputBorder _border() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey.shade300),
  );

  InputBorder _focusedBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: 2),
  );

  Widget _buildPrefixIcon(IconData icon) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
