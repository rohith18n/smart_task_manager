import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_header_widget.dart';
import '../widgets/register_actions_widget.dart';
import '../widgets/register_password_fields.dart';

class RegisterScreen extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ValueNotifier<bool> _obscurePasswordNotifier =
      ValueNotifier<bool>(true);
  final ValueNotifier<bool> _obscureConfirmPasswordNotifier =
      ValueNotifier<bool>(true);

  RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void onSignUp() {
      FocusScope.of(context).unfocus();
      if (_formKey.currentState!.validate()) {
        context.read<AuthBloc>().add(
              SignUpWithEmailEvent(
                email: _emailController.text.trim(),
                password: _passwordController.text,
                displayName: _nameController.text.trim(),
              ),
            );
      }
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, _) => IconButton(
              tooltip:
                  isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state.status == AuthStatus.authenticated) {
            context.go('/');
          }
        },
        builder: (context, state) {
          final isLoading = state.isLoading;

          return SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeaderWidget(
                      title: 'Create Account',
                      subtitle:
                          'Sign up to sync your tasks across all devices securely',
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Full Name *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'John Doe',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Email Address *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'name@example.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    RegisterPasswordFields(
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      obscurePasswordNotifier: _obscurePasswordNotifier,
                      obscureConfirmPasswordNotifier:
                          _obscureConfirmPasswordNotifier,
                      onSubmitted: onSignUp,
                    ),
                    const SizedBox(height: 28),
                    RegisterActionsWidget(
                      isLoading: isLoading,
                      onSignUp: onSignUp,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
