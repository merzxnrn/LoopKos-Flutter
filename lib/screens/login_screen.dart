import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/app_background.dart';
import '../widgets/ui_kit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _showPassword = false;
  bool _isSubmitting = false;
  String _errorMsg = '';

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _campus = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _toggleMode(bool toLogin) {
    if (toLogin == _isLogin) return;
    setState(() {
      _isLogin = toLogin;
      _formKey.currentState?.reset();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _campus = '';
      _errorMsg = '';
      _showPassword = false;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = readAuthOrNull(context);
    if (auth == null) {
      setState(() {
        _errorMsg = 'Layanan autentikasi belum tersedia saat ini.';
      });
      return;
    }

    setState(() {
      _errorMsg = '';
      _isSubmitting = true;
    });

    String? err;
    if (_isLogin) {
      err = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    } else {
      err = await auth.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        campus: _campus,
        phone: _phoneCtrl.text.trim(),
      );
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (err != null) {
        _errorMsg = err;
      }
    });
  }

  void _showForgotPasswordSheet() {
    _showInfoSheet(
      icon: Icons.lock_reset_rounded,
      title: 'Bantuan Reset Password',
      paragraphs: const [
        'Fitur reset password mandiri sedang kami siapkan agar kamu bisa memulihkan akun langsung lewat email terdaftar.',
        'Untuk sementara, hubungi tim admin LoopKos melalui WhatsApp resmi atau email support@loopkos.id dengan menyertakan email kampus akunmu untuk bantuan reset password.',
      ],
    );
  }

  void _showTermsSheet() {
    _showInfoSheet(
      icon: Icons.description_outlined,
      title: 'Syarat & Ketentuan LoopKos',
      paragraphs: const [
        '1. LoopKos adalah marketplace barang kos preloved khusus komunitas mahasiswa.',
        '2. Penjual wajib mencantumkan foto, kondisi, dan harga barang secara jujur serta tidak menjual barang terlarang.',
        '3. Transaksi dilakukan langsung antar mahasiswa dengan verifikasi pembayaran dan serah terima yang disepakati bersama.',
      ],
    );
  }

  void _showPrivacySheet() {
    _showInfoSheet(
      icon: Icons.privacy_tip_outlined,
      title: 'Kebijakan Privasi LoopKos',
      paragraphs: const [
        'Data profil seperti nama, email, kampus, dan nomor WhatsApp hanya digunakan untuk verifikasi akun dan memperlancar komunikasi antara pembeli dan penjual.',
        'LoopKos tidak pernah membagikan data pribadimu ke pihak ketiga tanpa persetujuanmu.',
      ],
    );
  }

  void _showInfoSheet({
    required IconData icon,
    required String title,
    required List<String> paragraphs,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(icon, color: AppColors.primaryText, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final p in paragraphs) ...[
                Text(
                  p,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Loop',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          TextSpan(
                            text: 'Kos',
                            style: TextStyle(color: AppColors.primaryText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isLogin ? 'Selamat Datang Kembali' : 'Buat Akun LoopKos',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin
                          ? 'Masuk untuk lanjut belanja & jual barang kos'
                          : 'Daftar gratis untuk jual-beli barang kos di kampusmu',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  _tabButton('Masuk', _isLogin, () => _toggleMode(true)),
                                  const SizedBox(width: 4),
                                  _tabButton('Daftar', !_isLogin, () => _toggleMode(false)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_errorMsg.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.destructive.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.destructive.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFFCA5A5),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMsg,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFFCA5A5),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (!_isLogin) ...[
                              _label('Nama Lengkap'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameCtrl,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Nama lengkap kamu',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.mutedForeground,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (!_isLogin && (value == null || value.trim().isEmpty)) {
                                    return 'Nama lengkap wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            _label('Email'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'email@kamu.com',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppColors.mutedForeground,
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Email wajib diisi';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            if (!_isLogin) ...[
                              Row(
                                children: [
                                  _label('Kampus'),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '(opsional)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _campus.isEmpty ? null : _campus,
                                dropdownColor: AppColors.card,
                                isExpanded: true,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.school_outlined,
                                    color: AppColors.mutedForeground,
                                    size: 20,
                                  ),
                                  hintText: 'Lewati — pilih nanti',
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: '',
                                    child: Text('Lewati — pilih nanti'),
                                  ),
                                  ...AppConstants.campusOptions.map(
                                    (c) => DropdownMenuItem<String>(
                                      value: c,
                                      child: Text(c, overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _campus = v ?? ''),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _label('No. Telepon'),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '(opsional)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: '08xx-xxxx-xxxx',
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: AppColors.mutedForeground,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _label('Password'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!_isSubmitting) _submit();
                              },
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Minimal 8 karakter',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.mutedForeground,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _showPassword
                                      ? 'Sembunyikan password'
                                      : 'Tampilkan password',
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.mutedForeground,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                              ),
                              validator: (value) {
                                final text = value ?? '';
                                if (_isLogin) {
                                  if (text.isEmpty) {
                                    return 'Password wajib diisi';
                                  }
                                } else {
                                  if (text.length < 8) {
                                    return 'Password minimal 8 karakter';
                                  }
                                }
                                return null;
                              },
                            ),
                            if (_isLogin) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordSheet,
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(48, 48),
                                    foregroundColor: AppColors.primaryText,
                                  ),
                                  child: const Text(
                                    'Lupa password?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ] else
                              const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isLogin ? 'Sedang masuk...' : 'Membuat akun...',
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isLogin ? 'Masuk ke Akun' : 'Buat Akun',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Dengan melanjutkan, kamu menyetujui ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          TextButton(
                            onPressed: _showTermsSheet,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              foregroundColor: AppColors.primaryText,
                            ),
                            child: const Text(
                              'Syarat & Ketentuan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Text(
                            '&',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          TextButton(
                            onPressed: _showPrivacySheet,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              foregroundColor: AppColors.primaryText,
                            ),
                            child: const Text(
                              'Kebijakan Privasi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
