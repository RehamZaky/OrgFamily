import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_photo_store.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/option_picker_sheet.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/family_members_table.dart';
import '../../../data/providers.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key, this.isFirstMember = false, this.existing});

  final bool isFirstMember;
  final FamilyMember? existing;

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  late final String _memberId = widget.existing?.id ?? const Uuid().v4();
  late final _nameController =
      TextEditingController(text: widget.existing?.name);
  late final _gradeController =
      TextEditingController(text: widget.existing?.grade);
  late final _schoolController =
      TextEditingController(text: widget.existing?.school);
  late final _notesController =
      TextEditingController(text: widget.existing?.notes);
  late String _emoji = widget.existing?.avatarEmoji ?? '👨';
  late String? _photoPath = widget.existing?.photoPath;
  late Color _color = widget.existing != null
      ? Color(widget.existing!.colorValue)
      : AppColors.avatarPalette.first;
  late FamilyRole _role = widget.existing?.role ?? FamilyRole.adult;
  late DateTime? _birthday = widget.existing?.birthday;

  static const _emojis = [
    '👨', '👩', '👧', '👦', '👵', '👴', '🧑',
  ];

  String? get _emojiAsset => memberAvatarAssets[_emoji];

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _schoolController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isFirstMember) _role = FamilyRole.owner;
  }

  Future<void> _pickPhoto() async {
    final path =
        await pickAndSaveAvatarPhoto(context: context, memberId: _memberId);
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _pickRole() async {
    final role = await showOptionPickerSheet<FamilyRole>(
      context: context,
      title: 'Role',
      options: FamilyRole.values,
      labelBuilder: (r) => r.label,
      selected: _role,
    );
    if (role != null) setState(() => _role = role);
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (date != null) setState(() => _birthday = date);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    // The very first member (onboarding) has no one to check permission
    // against yet — activeRoleProvider already resolves to Owner in that
    // case, so this guard is a no-op there and a real check afterward.
    if (!widget.isFirstMember && !checkPermission(context, ref, FamilyAction.manageMembers)) {
      return;
    }
    final actingRole = ref.read(activeRoleProvider);
    final repo = ref.read(familyRepositoryProvider);
    final grade = _gradeController.text.trim();
    final school = _schoolController.text.trim();
    final notes = _notesController.text.trim();
    if (widget.existing == null) {
      await repo.addMember(
        id: _memberId,
        name: name,
        avatarEmoji: _emoji,
        photoPath: _photoPath,
        colorValue: _color.toARGB32(),
        role: _role,
        birthday: _birthday,
        grade: grade.isEmpty ? null : grade,
        school: school.isEmpty ? null : school,
        notes: notes.isEmpty ? null : notes,
        actingRole: actingRole,
      );
    } else {
      await repo.updateMember(
        widget.existing!.copyWith(
          name: name,
          avatarEmoji: _emoji,
          photoPath: Value(_photoPath),
          colorValue: _color.toARGB32(),
          role: _role,
          birthday: Value(_birthday),
          grade: Value(grade.isEmpty ? null : grade),
          school: Value(school.isEmpty ? null : school),
          notes: Value(notes.isEmpty ? null : notes),
        ),
        actingRole: actingRole,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        leadingWidth: 80,
        title: Text(isEditing ? 'Edit member' : 'Add member'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: _color.withValues(alpha: 0.18),
                  backgroundImage: _photoPath != null
                      ? FileImage(File(_photoPath!))
                      : _emojiAsset != null
                          ? AssetImage(_emojiAsset!)
                          : null,
                  child: _photoPath == null && _emojiAsset == null
                      ? Text(_emoji, style: const TextStyle(fontSize: 40))
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: _pickPhoto,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _BoxedField(
            label: 'Name',
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Full name',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
          ),
          if (!widget.isFirstMember) ...[
            const SizedBox(height: 16),
            _BoxedField(
              label: 'Role',
              child: InkWell(
                onTap: _pickRole,
                child: Row(
                  children: [
                    Expanded(child: Text(_role.label)),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _BoxedField(
            label: 'Birthday',
            child: InkWell(
              onTap: _pickBirthday,
              child: Row(
                children: [
                  Expanded(
                    child: Text(_birthday == null
                        ? 'Not set'
                        : DateFormat('MMM d, y').format(_birthday!)),
                  ),
                  if (_birthday != null)
                    InkWell(
                      onTap: () => setState(() => _birthday = null),
                      child: Icon(Icons.close,
                          size: 18, color: Colors.grey.shade600),
                    ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _BoxedField(
            label: 'Grade (optional)',
            child: TextField(
              controller: _gradeController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'e.g. 2nd Grade',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 16),
          _BoxedField(
            label: 'School (optional)',
            child: TextField(
              controller: _schoolController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'e.g. El Noor School',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(height: 16),
          _BoxedField(
            label: 'Notes (optional)',
            child: TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'e.g. Loves reading and painting.',
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 28),
          Text('Or pick an emoji instead',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: _emojis.map((e) {
              final selected = _photoPath == null && e == _emoji;
              final asset = memberAvatarAssets[e];
              return GestureDetector(
                onTap: () => setState(() {
                  _emoji = e;
                  _photoPath = null;
                }),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: selected
                      ? _color.withValues(alpha: 0.25)
                      : Colors.grey.shade100,
                  backgroundImage: asset != null ? AssetImage(asset) : null,
                  child: asset == null
                      ? Text(e, style: const TextStyle(fontSize: 22))
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: AppColors.avatarPalette.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: c,
                  child: selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(widget.existing == null ? 'Save' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}

/// A labeled, bordered field container — label above, boxed content below —
/// matching the Add/Edit Member design (2026-09-01).
class _BoxedField extends StatelessWidget {
  const _BoxedField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
      ],
    );
  }
}
