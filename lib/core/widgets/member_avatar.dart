import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/local/database.dart';

/// Illustrated avatar art for the emoji options that have one, so members
/// get the same colorful 3D-illustration style used in onboarding instead
/// of a flat emoji glyph. Falls back to the emoji itself for the options
/// that don't have art yet (👵, 👴, 🧑). Public so the emoji picker in
/// add_member_screen.dart can preview the same art while choosing, instead
/// of showing a flat glyph there and the illustration everywhere else.
const memberAvatarAssets = {
  '👨': 'assets/onboarding/man-avatar.png',
  '👩': 'assets/onboarding/women-avatar.png',
  '👦': 'assets/onboarding/boy-avatar.png',
  '👧': 'assets/onboarding/girl-avatar.png',
};

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, this.member, this.radius = 20});

  final FamilyMember? member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final m = member;
    if (m == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person_outline, size: radius, color: Colors.grey),
      );
    }
    final photoPath = m.photoPath;
    if (photoPath != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Color(m.colorValue).withValues(alpha: 0.18),
        backgroundImage: FileImage(File(photoPath)),
      );
    }
    final asset = memberAvatarAssets[m.avatarEmoji];
    if (asset != null) {
      return ClipOval(
        child: Image.asset(
          asset,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Color(m.colorValue).withValues(alpha: 0.18),
      child: Text(
        m.avatarEmoji,
        style: TextStyle(fontSize: radius),
      ),
    );
  }
}
