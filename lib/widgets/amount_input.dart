import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A large, friendly amount field for the transaction entry flow.
/// Accepts digits and a single decimal point; validation of the final
/// value (e.g. non-empty, non-zero) happens where it's submitted.
class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;

  const AmountInput({super.key, required this.controller, this.errorText});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: Theme.of(context).textTheme.displaySmall,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        prefixText: '\$ ',
        prefixStyle: Theme.of(context).textTheme.displaySmall,
        border: InputBorder.none,
        errorText: errorText,
        hintText: '0.00',
      ),
    );
  }
}
