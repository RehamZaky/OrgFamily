import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/sync_outbox_table.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';

/// Lets the syncing member decide what happens to changes that only upload
/// on request — made while this phone wasn't syncing as them, or by
/// another account (see `SyncEngine.uploadHeld`/`discardHeld`). Lists each
/// change by name so the decision is an informed one, not a blind
/// "upload everything".
Future<void> showSyncReviewSheet(BuildContext context, List<SyncOutboxData> rows) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SyncReviewSheet(rows: rows),
  );
}

class _SyncReviewSheet extends ConsumerStatefulWidget {
  const _SyncReviewSheet({required this.rows});

  final List<SyncOutboxData> rows;

  @override
  ConsumerState<_SyncReviewSheet> createState() => _SyncReviewSheetState();
}

class _SyncReviewSheetState extends ConsumerState<_SyncReviewSheet> {
  late final Future<List<(SyncEntityType, String?)>> _items = _describe();
  bool _busy = false;

  /// One entry per changed entity (an entity edited several times is queued
  /// several times, but is one change to the person reviewing).
  Future<List<(SyncEntityType, String?)>> _describe() async {
    final db = ref.read(databaseProvider);
    final seen = <(SyncEntityType, String)>{};
    final items = <(SyncEntityType, String?)>[];
    for (final row in widget.rows) {
      if (!seen.add((row.entityType, row.entityId))) continue;
      items.add((row.entityType, await _nameOf(db, row.entityType, row.entityId)));
    }
    return items;
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
      SyncEntityType.familyProfile => '',
    };
  }

  String _typeLabel(AppLocalizations l10n, SyncEntityType type) => switch (type) {
        SyncEntityType.task => l10n.syncReviewTask,
        SyncEntityType.event => l10n.syncReviewEvent,
        SyncEntityType.shoppingItem => l10n.syncReviewShoppingItem,
        SyncEntityType.shoppingList => l10n.syncReviewShoppingList,
        SyncEntityType.familyMember => l10n.syncReviewMember,
        SyncEntityType.familyProfile => l10n.syncReviewFamily,
      };

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await action();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sync = ref.read(syncEngineProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.syncReviewTitle(
                widget.rows.map((r) => (r.entityType, r.entityId)).toSet().length,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.syncReviewSheetBody,
                style: TextStyle(color: context.colors.textSecondary)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
              child: FutureBuilder(
                future: _items,
                builder: (context, snapshot) {
                  final items = snapshot.data;
                  if (items == null) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final (type, name) in items)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            name == null
                                ? l10n.syncReviewDeleted
                                : name.isEmpty
                                    ? _typeLabel(l10n, type)
                                    : name,
                          ),
                          subtitle: name == null || name.isEmpty
                              ? null
                              : Text(_typeLabel(l10n, type)),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : () => _run(sync.uploadHeld),
              child: Text(l10n.syncReviewUpload),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => _run(sync.discardHeld),
              child: Text(l10n.syncReviewKeepLocal),
            ),
          ],
        ),
      ),
    );
  }
}
