import 'package:app_template/core/theme/app_colors.dart';
import 'package:app_template/core/theme/app_spacing.dart';
import 'package:app_template/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pill-shaped phone input: a raised +91 country code pill on the left,
/// borderless text field on the right.
///
/// Intentionally has no `maxLength` and no inline `onChanged` filled-state
/// logic — those responsibilities belong to the caller. Pass
/// [inputFormatters] (typically `[IndianPhoneInputFormatter()]`) and attach a
/// controller listener in the parent for the single source of truth on
/// validation state.
class AuthPhoneInput extends StatelessWidget {
  const AuthPhoneInput({
    super.key,
    required this.controller,
    required this.inputFormatters,
    this.readOnly = false,
  });

  final TextEditingController controller;

  /// Input formatters applied to the underlying [TextField]. Pass
  /// `[IndianPhoneInputFormatter()]` from the screen so that the formatter
  /// class stays co-located with the validation/listener logic.
  final List<TextInputFormatter> inputFormatters;

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              '+91',
              style: AppTypography.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.primaryDim,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AutofillGroup(
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberDevice],
                // maxLength is intentionally absent — see IndianPhoneInputFormatter.
                cursorColor: AppColors.primary,
                inputFormatters: inputFormatters,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                  hintText: 'Phone number',
                  hintStyle: AppTypography.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textDisabled,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
