import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: Consumer<AuthViewModel>(
        builder: (context, auth, _) {
          final user = auth.userProfile;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: (user?.photoUrl != null)
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          (user?.displayName?.isNotEmpty ?? false)
                              ? user!.displayName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'Người dùng',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                  title: const Text('Đăng xuất'),
                  onTap: () => context.read<AuthViewModel>().signOut(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
