// AmountInput — text field untuk nominal uang dengan prefix Rp dan auto-separator
// ribuan saat user mengetik.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';

class AmountInput extends StatefulWidget {
  const AmountInput({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialValue = 0,
    this.hint = '0',
    this.enabled = true,
  });

  final String label;
  final ValueChanged<int> onChanged;
  final int initialValue;
  final String hint;
  final bool enabled;

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue > 0
          ? formatRupiah(widget.initialValue.toDouble(), withSymbol: false)
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant AmountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to initialValue changes — mis. saat user pilih tagihan
    // dan nominal auto-fill dari outstanding tagihan.
    if (widget.initialValue != oldWidget.initialValue) {
      final newText = widget.initialValue > 0
          ? formatRupiah(widget.initialValue.toDouble(), withSymbol: false)
          : '';
      if (_controller.text != newText) {
        _controller.text = newText;
        _controller.selection =
            TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    // Strip non-digit, parse int, format, push value up.
    final digits = v.replaceAll(RegExp(r'[^\d]'), '');
    final amount = int.tryParse(digits) ?? 0;
    final formatted =
        amount > 0 ? formatRupiah(amount.toDouble(), withSymbol: false) : '';

    // Update controller tanpa trigger loop
    if (formatted != v) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    widget.onChanged(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Text(
                  'Rp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  enabled: widget.enabled,
                  onChanged: _onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
