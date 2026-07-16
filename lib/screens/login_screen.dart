import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Consumer<AuthViewModel>(
              builder: (context, auth, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.science_rounded,
                      size: 80,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.appName,
                      style: AppTextStyles.heading1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập để bắt đầu phân tích xu hướng nghiên cứu',
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (auth.errorMessage != null) ...[
                      Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    auth.isSigningIn
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            key: const Key('google_sign_in_button'),
                            onPressed: () =>
                                context.read<AuthViewModel>().signInWithGoogle(),
                            icon: const Icon(Icons.login_rounded),
                            label: const Text('Đăng nhập với Google'),
                          ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
