import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';

/// A single free-text note. No title field, no explicit Save button — the
/// note autosaves when you navigate away (matches how a physical sticky
/// note works: you just write on it and walk away).
class NoteFormScreen extends ConsumerStatefulWidget {
  const NoteFormScreen({super.key, this.existing});

  final Note? existing;

  @override
  ConsumerState<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends ConsumerState<NoteFormScreen> {
  late final _bodyController = TextEditingController(text: widget.existing?.body);
  late int _colorIndex = widget.existing?.colorIndex ?? 0;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _saveOrDiscard() async {
    final text = _bodyController.text.trim();
    final repo = ref.read(noteRepositoryProvider);
    final existing = widget.existing;

    if (text.isEmpty) {
      if (existing != null) await repo.deleteNote(existing.id);
      return;
    }
    if (existing == null) {
      await repo.addNote(id: const Uuid().v4(), body: text, colorIndex: _colorIndex);
    } else if (text != existing.body || _colorIndex != existing.colorIndex) {
      await repo.updateNote(existing.copyWith(body: text, colorIndex: _colorIndex));
    }
  }

  Future<void> _saveAndClose() async {
    await _saveOrDiscard();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = AppColors.notePalette[_colorIndex];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveOrDiscard();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: l10n.save,
              onPressed: _saveAndClose,
            ),
            if (widget.existing != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.delete,
                onPressed: () async {
                  await ref.read(noteRepositoryProvider).deleteNote(widget.existing!.id);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                children: [
                  for (var i = 0; i < AppColors.notePalette.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => _colorIndex = i),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.notePalette[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == _colorIndex
                                ? AppColors.textPrimary
                                : Colors.black.withValues(alpha: 0.1),
                            width: i == _colorIndex ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _bodyController,
                    autofocus: widget.existing == null,
                    expands: true,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: l10n.noteHint,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
