import 'package:drift/drift.dart';

import '../../local/database.dart';
import '../../local/tables/shopping_table.dart';
import '../../local/tables/sync_outbox_table.dart';
import '../sync_adapter.dart';
import '../sync_firestore_x.dart';

/// Mirrors [ShoppingLists] to `families/{familyId}/shoppingLists/{listId}`
/// — every field.
class ShoppingListSyncAdapter implements SyncAdapter<ShoppingList> {
  ShoppingListSyncAdapter(this._db);

  final AppDatabase _db;

  @override
  SyncEntityType get entityType => SyncEntityType.shoppingList;

  @override
  String collectionPath(String familyId) => 'families/$familyId/shoppingLists';

  @override
  DateTime updatedAtOf(ShoppingList row) => row.updatedAt;

  @override
  DateTime? deletedAtOf(ShoppingList row) => row.deletedAt;

  @override
  Map<String, dynamic> toFirestoreFields(ShoppingList row) {
    return {
      'name': row.name,
      'emoji': row.emoji,
      'createdAt': row.createdAt,
      'deletedAt': row.deletedAt,
    };
  }

  @override
  Future<ShoppingList?> getLocalById(String id) {
    // Deliberately unfiltered by deletedAt — see FamilyMemberSyncAdapter's
    // doc comment on getLocalById for why.
    return (_db.select(_db.shoppingLists)..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<List<String>> allLocalIds(String familyId) async {
    final rows = await _db.select(_db.shoppingLists).get();
    return rows.map((r) => r.id).toList();
  }

  @override
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt) {
    return _db.into(_db.shoppingLists).insertOnConflictUpdate(
          ShoppingListsCompanion.insert(
            id: id,
            name: fields['name'] as String,
            emoji: Value(fields['emoji'] as String? ?? '🛒'),
            createdAt: Value(toDateOrNull(fields['createdAt']) ?? DateTime.now()),
            updatedAt: Value(updatedAt),
            deletedAt: Value(toDateOrNull(fields['deletedAt'])),
          ),
        );
  }
}
