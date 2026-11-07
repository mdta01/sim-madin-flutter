// Forgot PIN — 3-step OTP flow (request → verify → set new PIN).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

class ForgotPinScreen extends ConsumerStatefulWidget {
  const ForgotPinScreen({super.key});
  @override
  ConsumerState<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends ConsumerState<ForgotPinScreen> {
  int _step = 0; // 0=phone, 1=otp, 2=setPin
  bool _loading = false;
  // Hanya terisi kalau admin menyalakan SystemSetting OTP_DEBUG.
  // Di production nilainya null: OTP dikirim lewat notifikasi/WhatsApp.
  String? _devOtp;
  String? _verifyToken;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      _toast('Nomor WhatsApp wajib diisi', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await requestOtp(ref,
          phone: _phoneController.text.trim(), type: 'FORGOT_PIN');
      if (!mounted) return;
      // Server yang memutuskan apakah OTP boleh ditampilkan (mode debug).
      // Di production `debugOtp` selalu null.
      setState(() {
        _devOtp = kDebugMode ? result.debugOtp : null;
        _step = 1;
      });
      _toast(result.message);
    } catch (e) {
      if (mounted) _toast('Gagal: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _toast('OTP harus 6 digit', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await verifyOtp(ref,
          phone: _phoneController.text.trim(),
          otpCode: _otpController.text);
      if (!mounted) return;
      setState(() {
        _verifyToken = token;
        _step = 2;
      });
      _toast('✅ OTP terverifikasi. Set PIN baru.');
    } catch (e) {
      if (mounted) _toast('Gagal: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setNewPin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;
    if (pin.length != 6) {
      _toast('PIN harus 6 digit', isError: true);
      return;
    }
    if (pin != confirmPin) {
      _toast('PIN tidak cocok', isError: true);
      return;
    }
    if (_verifyToken == null) {
      _toast('Token verifikasi tidak valid', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await setNewPin(ref,
          verifyToken: _verifyToken!, newPin: pin);
      if (!mounted) return;
      _toast('✅ PIN berhasil diubah. Silakan login.');
      context.go('/login');
    } catch (e) {
      if (mounted) _toast('Gagal: ${friendlyError(e)}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppColors.danger : AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Icon(Icons.key, size: 80, color: AppColors.white),
              const SizedBox(height: 16),
              const Text('Lupa PIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Reset PIN via OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.white, fontSize: 16)),
              const SizedBox(height: 48),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildStep(),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Masukkan Nomor WhatsApp',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Kami akan kirim kode OTP ke nomor Anda',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp',
                hintText: '08xxx atau 628xxx',
                prefixIcon: Icon(Icons.call),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _requestOtp,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kirim OTP'),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Verifikasi OTP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Masukkan 6 digit kode yang dikirim',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            if (kDebugMode && _devOtp != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DEV MODE — OTP Anda: $_devOtp',
                  style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  letterSpacing: 8, fontSize: 24, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _verifyOtp,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verifikasi'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : _requestOtp,
              child: const Text('Kirim ulang OTP'),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Buat PIN Baru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('PIN 6 digit untuk login',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  letterSpacing: 6, fontSize: 20, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                labelText: 'PIN Baru',
                hintText: '••••••',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  letterSpacing: 6, fontSize: 20, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                labelText: 'Konfirmasi PIN',
                hintText: '••••••',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _setNewPin,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan PIN Baru'),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
