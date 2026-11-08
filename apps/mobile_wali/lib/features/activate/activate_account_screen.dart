// Aktivasi Akun Wali — PIN pertama.
//
// Alur (sesuai permintaan):
//   1. Wali memasukkan nomor WhatsApp yang sudah didaftarkan admin.
//   2. Sistem memeriksa nomor tersebut ADA di data admin, lalu menampilkan
//      nama wali + nama anak sebagai konfirmasi ("benar ini akun saya").
//   3. Wali membuat PIN 6 digit dan mengetik ulang sebagai konfirmasi.
//   4. PIN disimpan (bcrypt) di baris Wali yang terhubung dengan nomor itu.
//   5. Wali login memakai nomor + PIN.
//
// Kalau PIN lupa: tombol "Lupa PIN" -> alur OTP WhatsApp (sudah ada).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

class ActivateAccountScreen extends ConsumerStatefulWidget {
  const ActivateAccountScreen({super.key});
  @override
  ConsumerState<ActivateAccountScreen> createState() =>
      _ActivateAccountScreenState();
}

class _ActivateAccountScreenState extends ConsumerState<ActivateAccountScreen> {
  int _step = 0; // 0 = nomor, 1 = buat PIN

  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _showPin = false;

  WaliRegistrationCheck? _check;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _checkPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _toast('Nomor WhatsApp wajib diisi', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await checkWaliRegistration(ref, phone: phone);

      if (!mounted) return;
      if (!result.registered) {
        _toast(result.message, isError: true);
        return;
      }

      // Nomor terdaftar tetapi PIN sudah ada -> arahkan ke Lupa PIN,
      // bukan menimpa PIN orang lain.
      if (!result.needsPin) {
        _toast(
          'PIN untuk nomor ini sudah dibuat. Gunakan "Lupa PIN" bila perlu '
          'mengubahnya.',
          isError: true,
        );
        return;
      }

      setState(() {
        _check = result;
        _step = 1;
      });
    } catch (e) {
      if (mounted) _toast(friendlyError(e), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _activate() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length != 6) {
      _toast('PIN harus 6 digit', isError: true);
      return;
    }
    if (pin != confirm) {
      _toast('Konfirmasi PIN tidak sama', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final message = await activateWali(
        ref,
        phone: _phoneController.text.trim(),
        pin: pin,
        pinConfirm: confirm,
      );
      if (!mounted) return;
      _toast('✅ $message');
      context.go('/login');
    } catch (e) {
      if (mounted) _toast(friendlyError(e), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.white,
        title: const Text('Aktivasi Akun'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                _step == 0 ? Icons.verified_user : Icons.lock_outline,
                size: 72,
                color: AppColors.white,
              ),
              const SizedBox(height: 12),
              Text(
                _step == 0 ? 'Aktivasi Pertama' : 'Buat PIN',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _step == 0
                    ? 'Gunakan nomor WhatsApp yang sudah didaftarkan admin madrasah'
                    : 'PIN ini dipakai untuk masuk ke aplikasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _step == 0 ? _buildPhoneStep() : _buildPinStep(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Kembali ke Login'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/forgot-pin'),
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Lupa PIN'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Langkah 1 — nomor WhatsApp
  // ---------------------------------------------------------------------
  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nomor WhatsApp',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'Nomor ini harus sudah terdaftar oleh admin madrasah. '
          'Kalau belum, hubungi admin untuk didaftarkan.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _checkPhone(),
          decoration: const InputDecoration(
            labelText: 'Nomor WhatsApp',
            hintText: '08xxx atau 628xxx',
            prefixIcon: Icon(Icons.call),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _checkPhone,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Periksa Nomor'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Langkah 2 — konfirmasi data + buat PIN
  // ---------------------------------------------------------------------
  Widget _buildPinStep() {
    final check = _check;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Konfirmasi identitas ---
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nomor terdaftar atas nama ${check?.name ?? '-'}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              if ((check?.anak ?? const []).isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Anak Anda:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                ...check!.anak.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(left: 28, top: 2),
                    child: Text(
                      '• ${c.name}'
                      '${c.nis != null ? ' (NIS ${c.nis})' : ''}'
                      '${c.kelasName != null ? ' — ${c.kelasName}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('Buat PIN (6 digit)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'Hindari PIN yang mudah ditebak seperti 123456 atau 000000.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _pinController,
          obscureText: !_showPin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(letterSpacing: 8, fontSize: 20),
          decoration: InputDecoration(
            labelText: 'PIN',
            hintText: '••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showPin = !_showPin),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _confirmController,
          obscureText: !_showPin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(letterSpacing: 8, fontSize: 20),
          decoration: const InputDecoration(
            labelText: 'Konfirmasi PIN',
            hintText: '••••••',
            prefixIcon: Icon(Icons.lock_reset),
            counterText: '',
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _loading ? null : _activate,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Aktifkan Akun'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading
              ? null
              : () => setState(() {
                    _step = 0;
                    _check = null;
                    _pinController.clear();
                    _confirmController.clear();
                  }),
          child: const Text('Ganti nomor'),
        ),
      ],
    );
  }
}
