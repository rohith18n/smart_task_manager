import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterPasswordFields extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final ValueNotifier<bool> obscurePasswordNotifier;
  final ValueNotifier<bool> obscureConfirmPasswordNotifier;
  final VoidCallback onSubmitted;

  const RegisterPasswordFields({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePasswordNotifier,
    required this.obscureConfirmPasswordNotifier,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: obscurePasswordNotifier,
          builder: (context, isObscured, _) {
            return TextFormField(
              controller: passwordController,
              obscureText: isObscured,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'At least 6 characters',
                prefixIcon:
                    const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    obscurePasswordNotifier.value = !isObscured;
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Confirm Password *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: obscureConfirmPasswordNotifier,
          builder: (context, isObscured, _) {
            return TextFormField(
              controller: confirmPasswordController,
              obscureText: isObscured,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmitted(),
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Re-enter your password',
                prefixIcon:
                    const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () {
                    obscureConfirmPasswordNotifier.value = !isObscured;
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }
}
