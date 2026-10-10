import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/sync_outbox_table.dart';
import '../../../data/providers.dart';
import '../../../data/sync/sync_engine.dart';
import '../../../l10n/app_localizations.dart';

/// Lets the syncing member decide, change by change, what happens to
/// changes that only upload on request — made while this phone wasn't
/// syncing as them, or by another account. Each one is first compared with
/// its live cloud version ([SyncEngine.inspectReview]): an upload
/// overwrites the cloud copy, so anything the cloud has a newer version of
/// defaults to the cloud version, and only changes that can't overwrite
/// newer information default to uploading.
Future<void> showSyncReviewSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _SyncReviewSheet(),
  );
}

class _Entry {
  _Entry(this.item, this.name) : choice = item.defaultChoice;

  final ReviewItem item;

  /// Null when the entity is gone from this phone; empty for the family
  /// settings singleton, which has no name of its own.
  final String? name;
  ReviewChoice choice;
}

class _SyncReviewSheet extends ConsumerStatefulWidget {
  const _SyncReviewSheet();

  @override
  ConsumerState<_SyncReviewSheet> createState() => _SyncReviewSheetState();
}

class _SyncReviewSheetState extends ConsumerState<_SyncReviewSheet> {
  late Future<List<_Entry>> _entries = _load();
  bool _busy = false;

  /// (done, total) while applying; null otherwise.
  (int, int)? _progress;

  Future<List<_Entry>> _load() async {
    final db = ref.read(databaseProvider);
    final items = await ref.read(syncEngineProvider).inspectReview();
    return [
      for (final item in items) _Entry(item, await _nameOf(db, item.type, item.entityId)),
    ];
  }

  Future<String?> _nameOf(AppDatabase db, SyncEntityType type, String id) async {
    return switch (type) {
      SyncEntityType.task => (await (db.select(db.tasks)..where((t) => t.id.equals(id)))
              .getSingleOrNull())
          ?.title,
      SyncEntityType.event => (await (db.select(db.events)..where((e) => e.id.equals(id)))
              .getSingleOrNull())
          ?.title,
      SyncEntityType.shoppingItem =>
        (await (db.select(db.shoppingItems)..where((i) => i.id.equals(id))).getSingleOrNull())
            ?.name,
      SyncEntityType.shoppingList =>
        (await (db.select(db.shoppingLists)..where((l) => l.id.equals(id))).getSingleOrNull())
            ?.name,
      SyncEntityType.familyMember =>
        (await (db.select(db.familyMembers)..where((m) => m.id.equals(id))).getSingleOrNull())
            ?.name,
      SyncEntityType.responsibility =>
        (await (db.select(db.responsibilities)..where((r) => r.id.equals(id))).getSingleOrNull())
            ?.title,
      SyncEntityType.familyProfile => '',
    };
  }

  String _typeLabel(AppLocalizations l10n, SyncEntityType type) => switch (type) {
        SyncEntityType.task => l10n.syncReviewTask,
        SyncEntityType.event => l10n.syncReviewEvent,
        SyncEntityType.shoppingItem => l10n.syncReviewShoppingItem,
        SyncEntityType.shoppingList => l10n.syncReviewShoppingList,
        SyncEntityType.familyMember => l10n.syncReviewMember,
        SyncEntityType.responsibility => l10n.syncReviewResponsibility,
        SyncEntityType.familyProfile => l10n.syncReviewFamily,
      };

  String _stateLabel(AppLocalizations l10n, ReviewItem item, String locale) {
    final cloudTime = item.remoteUpdatedAt == null
        ? ''
        : ' · ${DateFormat.MMMd(locale).add_jm().format(item.remoteUpdatedAt!.toLocal())}';
    return switch (item.state) {
      ReviewState.newOnPhone => l10n.syncReviewStateNew,
      ReviewState.phoneNewer => l10n.syncReviewStatePhoneNewer,
      ReviewState.cloudNewer => '${l10n.syncReviewStateCloudNewer}$cloudTime',
      ReviewState.inSync => l10n.syncReviewStateInSync,
      ReviewState.goneLocally => l10n.syncReviewDeleted,
    };
  }

  /// "Use cloud" needs a cloud version; "Upload" needs something on this
  /// phone to send.
  List<ReviewChoice> _choicesFor(ReviewItem item) => [
        if (item.state != ReviewState.goneLocally) ReviewChoice.upload,
        if (item.remoteUpdatedAt != null) ReviewChoice.useCloud,
        ReviewChoice.phoneOnly,
      ];

  String _choiceLabel(AppLocalizations l10n, ReviewChoice choice) => switch (choice) {
        ReviewChoice.upload => l10n.syncReviewChoiceUpload,
        ReviewChoice.useCloud => l10n.syncReviewChoiceUseCloud,
        ReviewChoice.phoneOnly => l10n.syncReviewChoicePhoneOnly,
      };

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // Most likely went offline mid-apply; whatever wasn't resolved stays
      // awaiting review, so reload to show what's left.
      if (mounted) {
        setState(() {
          _busy = false;
          _progress = null;
          _entries = _load();
        });
      }
    }
  }

  Future<void> _apply(List<_Entry> entries) {
    return _run(() => ref.read(syncEngineProvider).resolveReview(
          {for (final e in entries) (e.item.type, e.item.entityId): e.choice},
          onProgress: (done, total) {
            if (mounted) setState(() => _progress = (done, total));
          },
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final sync = ref.read(syncEngineProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: FutureBuilder<List<_Entry>>(
          future: _entries,
          builder: (context, snapshot) {
            final entries = snapshot.data;
            final failed = snapshot.hasError;
            final conflicts =
                entries?.where((e) => e.item.state == ReviewState.cloudNewer).length ?? 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entries != null)
                  Text(
                    l10n.syncReviewTitle(entries.length),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 8),
                Text(l10n.syncReviewSheetBody,
                    style: TextStyle(color: context.colors.textSecondary)),
                if (conflicts > 0) ...[
                  const SizedBox(height: 8),
                  Text(l10n.syncReviewConflicts(conflicts),
                      style: TextStyle(
                          color: context.colors.warning, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 12),
                if (failed) ...[
                  Text(l10n.syncReviewCheckFailed,
                      style: TextStyle(color: context.colors.danger)),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => setState(() => _entries = _load()),
                      child: Text(l10n.restoreFamilyRetry),
                    ),
                  ),
                ] else if (entries == null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(l10n.syncReviewChecking),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final entry in entries)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              entry.name == null || entry.name!.isEmpty
                                  ? _typeLabel(l10n, entry.item.type)
                                  : '${entry.name} · ${_typeLabel(l10n, entry.item.type)}',
                            ),
                            subtitle: Text(
                              _stateLabel(l10n, entry.item, locale),
                              style: entry.item.state == ReviewState.cloudNewer
                                  ? TextStyle(color: context.colors.warning)
                                  : null,
                            ),
                            trailing: DropdownButton<ReviewChoice>(
                              value: entry.choice,
                              underline: const SizedBox.shrink(),
                              onChanged: _busy
                                  ? null
                                  : (c) => setState(() => entry.choice = c ?? entry.choice),
                              items: [
                                for (final c in _choicesFor(entry.item))
                                  DropdownMenuItem(value: c, child: Text(_choiceLabel(l10n, c))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (_busy) ...[
                  LinearProgressIndicator(
                    value: switch (_progress) {
                      (final done, final total) when total > 0 => done / total,
                      _ => null,
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_progress case (final done, final total))
                    Text(l10n.syncReviewApplying(done, total),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.textSecondary)),
                  const SizedBox(height: 8),
                ],
                FilledButton(
                  onPressed: _busy || entries == null ? null : () => _apply(entries),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.syncReviewApply),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(sync.discardHeld),
                  child: Text(l10n.syncReviewKeepLocal),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
