import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/local/database.dart';

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
