import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lend_ledger/models/auth/user_profile.dart';
import 'package:lend_ledger/theme/theme.dart';
import 'package:lend_ledger/utils/image_data_utils.dart';

class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    super.key,
    required this.profile,
    this.radius = 36,
    this.localImagePath,
  });

  final UserProfile? profile;
  final double radius;
  final String? localImagePath;

  @override
  Widget build(BuildContext context) {
    final path = localImagePath?.trim();
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return CircleAvatar(
          key: ValueKey('local_$path'),
          radius: radius,
          backgroundColor: AppTheme.peach.withValues(alpha: 0.3),
          backgroundImage: FileImage(file),
        );
      }
    }

    final bytes = ImageDataUtils.decodeToBytes(profile?.profilePicture);
    if (bytes != null) {
      return CircleAvatar(
        key: ValueKey('remote_${profile?.id}_${bytes.length}'),
        radius: radius,
        backgroundImage: MemoryImage(bytes),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.peach.withValues(alpha: 0.45),
      child: Text(
        profile?.displayInitials ?? '?',
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF5C4542),
        ),
      ),
    );
  }
}
