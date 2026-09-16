import 'package:drift/drift.dart';

import '../../local/database.dart';
import '../../local/tables/shopping_table.dart';
import '../../local/tables/sync_outbox_table.dart';
import '../sync_adapter.dart';
import '../sync_firestore_x.dart';

/// Mirrors [ShoppingItems] to
/// `families/{familyId}/shoppingItems/{itemId}` — flat (not nested under
/// its list), with a `listId` field, matching the Drift table's own shape.
class ShoppingItemSyncAdapter implements SyncAdapter<ShoppingItem> {
  ShoppingItemSyncAdapter(this._db);

  final AppDatabase _db;

  @override
  SyncEntityType get entityType => SyncEntityType.shoppingItem;

  @override
  String collectionPath(String familyId) => 'families/$familyId/shoppingItems';

  @override
  DateTime updatedAtOf(ShoppingItem row) => row.updatedAt;

  @override
  DateTime? deletedAtOf(ShoppingItem row) => row.deletedAt;

  @override
  Map<String, dynamic> toFirestoreFields(ShoppingItem row) {
    return {
      'listId': row.listId,
      'name': row.name,
      'quantity': row.quantity,
      'isPurchased': row.isPurchased,
      'addedById': row.addedById,
      'createdAt': row.createdAt,
      'deletedAt': row.deletedAt,
    };
  }

  @override
  Future<ShoppingItem?> getLocalById(String id) {
    // Deliberately unfiltered by deletedAt — see FamilyMemberSyncAdapter's
    // doc comment on getLocalById for why.
    return (_db.select(_db.shoppingItems)..where((i) => i.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt) {
    return _db.into(_db.shoppingItems).insertOnConflictUpdate(
          ShoppingItemsCompanion.insert(
            id: id,
            listId: fields['listId'] as String,
            name: fields['name'] as String,
            quantity: Value(fields['quantity'] as String?),
            isPurchased: Value(fields['isPurchased'] as bool? ?? false),
            addedById: Value(fields['addedById'] as String?),
            createdAt: Value(toDateOrNull(fields['createdAt']) ?? DateTime.now()),
            updatedAt: Value(updatedAt),
            deletedAt: Value(toDateOrNull(fields['deletedAt'])),
          ),
        );
  }
}
