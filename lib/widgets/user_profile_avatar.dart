import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lend_ledger/models/auth/user_profile.dart';
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
    final provider = _resolveImageProvider();
    if (provider != null) {
      return CircleAvatar(radius: radius, backgroundImage: provider);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.indigo.shade100,
      child: Text(
        profile?.displayInitials ?? '?',
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade800,
        ),
      ),
    );
  }

  ImageProvider? _resolveImageProvider() {
    final path = localImagePath?.trim();
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
    }

    final bytes = ImageDataUtils.decodeToBytes(profile?.profilePicture);
    if (bytes != null) return MemoryImage(bytes);
    return null;
  }
}
