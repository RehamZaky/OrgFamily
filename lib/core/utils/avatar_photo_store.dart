import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies a picked image into the app's own documents directory (under
/// `avatars/`) so it survives after the picker's temp file is cleaned up,
/// and returns the saved path.
Future<String> saveAvatarPhoto(XFile picked, String memberId) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final avatarsDir = Directory('${docsDir.path}/avatars');
  if (!await avatarsDir.exists()) {
    await avatarsDir.create(recursive: true);
  }
  final extension = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
  final savedFile = File('${avatarsDir.path}/$memberId.$extension');
  await savedFile.writeAsBytes(await picked.readAsBytes());
  return savedFile.path;
}

/// Shows a "Take photo" / "Choose from gallery" action sheet and returns the
/// saved local file path, or null if the user cancelled.
Future<String?> pickAndSaveAvatarPhoto({
  required BuildContext context,
  required String memberId,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final picked = await ImagePicker()
      .pickImage(source: source, maxWidth: 800, imageQuality: 85);
  if (picked == null) return null;
  return saveAvatarPhoto(picked, memberId);
}
