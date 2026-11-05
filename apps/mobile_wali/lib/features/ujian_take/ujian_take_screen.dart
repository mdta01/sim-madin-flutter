// Ujian Take Screen — timer + Fisher-Yates shuffle + anti-cheat + recovery.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:api_client/api_client.dart';

import '../../widgets/anti_cheat_mixin.dart';
import '../../widgets/feedback_widgets.dart';

class UjianTakeScreen extends ConsumerStatefulWidget {
  const UjianTakeScreen({
    super.key,
    required this.ujianId,
    required this.santriId,
  });
  final String ujianId;
  final String santriId;

  @override
  ConsumerState<UjianTakeScreen> createState() => _UjianTakeScreenState();
}

class _UjianTakeScreenState extends ConsumerState<UjianTakeScreen>
    with WidgetsBindingObserver, AntiCheatMixin {
  UjianTakeData? _data;
  UjianSesiData? _sesi;
  bool _loading = true;
  String? _error;

  // State ujian
  int _currentSoal = 0;
  final Map<String, _AnswerState> _answers = {};
  // Cache TextField controllers per soal ID supaya tidak di-recreate
  // setiap rebuild (yang akan dismiss keyboard + kehilangan fokus).
  final Map<String, TextEditingController> _essayControllers = {};
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _submitting = false;
  double? _resultScore;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUjian();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Dispose semua cached essay controllers supaya tidak leak.
    for (final c in _essayControllers.values) {
      c.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onAppLifecycleChanged(state);
  }

  @override
  void onWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 5)),
    );
  }

  @override
  void onCheatDetected(String reason) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Ujian Di-submit Otomatis'),
        content: Text(reason),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _doSubmit(auto: true);
              },
              child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _loadUjian() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Start or resume sesi
      _sesi = await startUjianSesi(
        ref,
        ujianId: widget.ujianId,
        santriId: widget.santriId,
      );

      // Get ujian + soal list
      _data = await ref.read(
          ujianDetailForWaliProvider((ujianId: widget.ujianId, santriId: widget.santriId)).future);

      if (_data == null) {
        setState(() {
          _error = 'Ujian tidak ditemukan';
          _loading = false;
        });
        return;
      }

      // Init answers from existing (kalau resume sesi)
      for (final soal in _data!.soalList) {
        final existing = _data!.existingAnswers
            .where((a) => a.ujianSoalId == soal.id)
            .firstOrNull;
        _answers[soal.id] = _AnswerState(
          answer: existing?.answer ?? '',
          optionOrder: existing?.optionOrder,
        );
      }

      // Calculate remaining time
      final durationSec = _data!.ujian.durationMnt * 60;
      final elapsedSec = _sesi!.startTime != null
          ? DateTime.now().difference(_sesi!.startTime!).inSeconds
          : 0;
      _remainingSeconds = (durationSec - elapsedSec).clamp(0, durationSec);

      // Start timer
      _startTimer();

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _timer?.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds <= 1) {
          _remainingSeconds = 0;
          _timer?.cancel();
          _onTimeUp();
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  void _onTimeUp() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Waktu Habis'),
        content: const Text(
            'Waktu ujian telah berakhir. Jawaban akan dikumpulkan otomatis.'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _doSubmit(auto: true);
              },
              child: const Text('OK')),
        ],
      ),
    );
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _setAnswer(String ujianSoalId, String answer) {
    setState(() {
      _answers[ujianSoalId] = _AnswerState(
        answer: answer,
        optionOrder: _answers[ujianSoalId]?.optionOrder,
      );
    });
  }

  Future<void> _doSubmit({bool auto = false}) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();

    try {
      final answers = _answers.entries
          .map((e) => UjianJawabanSubmit(
                ujianSoalId: e.key,
                answer: e.value.answer,
                optionOrder: e.value.optionOrder,
              ))
          .toList();

      final score = await submitUjianJawaban(
        ref,
        sesiId: _sesi!.id,
        ujianId: widget.ujianId,
        santriId: widget.santriId,
        answers: answers,
        auto: auto,
      );

      setState(() => _resultScore = score);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal submit: ${friendlyError(e)}'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _confirmSubmit() {
    final answered = _answers.values.where((a) => a.answer.isNotEmpty).length;
    final total = _data?.soalList.length ?? 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Submit'),
        content: Text(
            'Anda telah menjawab $answered dari $total soal. '
            'Yakin ingin mengumpulkan? Jawaban tidak bisa diubah setelah submit.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.white),
            onPressed: () {
              Navigator.of(context).pop();
              _doSubmit(auto: false);
            },
            child: const Text('Kumpulkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ujian')),
        body: const Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat soal ujian...'),
          ],
        )),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ujian')),
        body: ErrorView(
          message: _error!,
          onRetry: () {
            context.pop();
          },
        ),
      );
    }

    if (_resultScore != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hasil Ujian'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _resultScore! >= 70
                      ? Icons.celebration
                      : Icons.sentiment_dissatisfied,
                  size: 80,
                  color: _resultScore! >= 70
                      ? AppColors.success
                      : AppColors.danger,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Ujian Selesai',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.lg),
                Text(_resultScore!.toStringAsFixed(0),
                    style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: _resultScore! >= 70
                            ? AppColors.success
                            : AppColors.danger)),
                const Text('/ 100',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textMuted)),
                const SizedBox(height: AppSpacing.md),
                Text(
                    _resultScore! >= 70
                        ? 'Alhamdulillah, Anda lulus ujian.'
                        : 'Anda belum mencapai KKM (70). Tetap semangat!',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textMuted),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.check),
                  label: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final ujian = _data!.ujian;
    final soalList = _data!.soalList;
    final soal = soalList[_currentSoal];
    final answeredCount = _answers.values.where((a) => a.answer.isNotEmpty).length;
    final isLowTime = _remainingSeconds < 60;

    // Parse options (JSON string for PG)
    List<String>? options;
    if (soal.type == SoalType.pg && soal.options != null) {
      try {
        // BankSoal.options disimpan sebagai JSON string like '["opt1","opt2",...]'
        final decoded = soal.options!.replaceAll("'", '"');
        options = (decoded.startsWith('[')
            ? List<String>.from(_parseJsonList(decoded))
            : decoded.split(',').map((s) => s.trim()).toList());
      } catch (_) {
        options = soal.options!.split(',').map((s) => s.trim()).toList();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Keluar Ujian?'),
            content: const Text(
                'Progres jawaban Anda tetap tersimpan. Anda bisa melanjutkan nanti.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Lanjut Ujian')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(ujian.title, style: const TextStyle(fontSize: 14)),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.md),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isLowTime
                    ? AppColors.dangerLight
                    : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer,
                      size: 14,
                      color: isLowTime
                          ? AppColors.danger
                          : AppColors.primary),
                  const SizedBox(width: 4),
                  Text(_formatTime(_remainingSeconds),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isLowTime
                              ? AppColors.danger
                              : AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress bar
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              color: AppColors.background,
              child: Row(
                children: [
                  Text(
                      'Soal ${_currentSoal + 1}/${soalList.length} • Terjawab: $answeredCount',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            // Question + options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Soal #${_currentSoal + 1}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(soal.question ?? '(soal tidak ditemukan)',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (soal.type == SoalType.pg && options != null) ...[
                    ...options.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final opt = entry.value;
                      final letter = String.fromCharCode(65 + idx);
                      final selected =
                          _answers[soal.id]?.answer == letter;
                      return Card(
                        margin:
                            const EdgeInsets.only(bottom: AppSpacing.xs),
                        color: selected
                            ? AppColors.primaryLight
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          side: BorderSide(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () => _setAnswer(soal.id, letter),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(letter,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selected
                                                ? AppColors.white
                                                : AppColors.text)),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                    child: Text(opt,
                                        style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ] else if (soal.type == SoalType.isian ||
                      soal.type == SoalType.essay) ...[
                    TextField(
                      decoration: InputDecoration(
                        hintText: soal.type == SoalType.isian
                            ? 'Jawaban singkat...'
                            : 'Tulis jawaban essay...',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: soal.type == SoalType.essay ? 5 : 1,
                      // CRITICAL: pakai cached controller per soal.id.
                      // Kalau dibuat baru di setiap rebuild, keyboard akan
                      // dismiss setelah 1 karakter (focus loss).
                      controller: _essayControllers.putIfAbsent(
                        soal.id,
                        () => TextEditingController(
                            text: _answers[soal.id]?.answer ?? ''),
                      ),
                      onChanged: (v) => _setAnswer(soal.id, v),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Text(
                          'Soal praktik — jawaban diinput manual oleh guru setelah ujian.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  // Navigation
                  Row(
                    children: [
                      if (_currentSoal > 0)
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _currentSoal--),
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Prev'),
                        ),
                      const Spacer(),
                      if (_currentSoal < soalList.length - 1)
                        FilledButton.icon(
                          onPressed: () =>
                              setState(() => _currentSoal++),
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Next'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _submitting
                              ? null
                              : _confirmSubmit,
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.success),
                          icon: _submitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white))
                              : const Icon(Icons.check),
                          label: const Text('Kumpulkan'),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Soal navigator (jump to specific soal)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: soalList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final answered = _answers[entry.value.id]
                              ?.answer
                              .isNotEmpty ??
                          false;
                      final isCurrent = idx == _currentSoal;
                      return InkWell(
                        onTap: () =>
                            setState(() => _currentSoal = idx),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primary
                                : answered
                                    ? AppColors.successLight
                                    : AppColors.background,
                            border: Border.all(
                                color: isCurrent
                                    ? AppColors.primary
                                    : answered
                                        ? AppColors.success
                                        : AppColors.border),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
                                      ? AppColors.white
                                      : answered
                                          ? AppColors.success
                                          : AppColors.textMuted),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple JSON list parser (Phase 5 — doesn't handle nested objects).
  List<dynamic> _parseJsonList(String json) {
    try {
      // Remove outer brackets
      final inner = json.trim();
      if (!inner.startsWith('[') || !inner.endsWith(']')) return [];
      final content = inner.substring(1, inner.length - 1).trim();
      if (content.isEmpty) return [];
      // Split by comma (assumes no commas inside strings)
      final items = <String>[];
      var inString = false;
      var current = StringBuffer();
      for (var i = 0; i < content.length; i++) {
        final ch = content[i];
        if (ch == '"' && (i == 0 || content[i - 1] != '\\')) {
          inString = !inString;
        } else if (ch == ',' && !inString) {
          items.add(current.toString().trim());
          current = StringBuffer();
          continue;
        }
        current.write(ch);
      }
      if (current.toString().trim().isNotEmpty) {
        items.add(current.toString().trim());
      }
      // Clean up quotes
      return items
          .map((s) => s.trim().replaceAll('"', '').replaceAll("'", ''))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class _AnswerState {
  _AnswerState({required this.answer, this.optionOrder});
  String answer;
  String? optionOrder;
}
