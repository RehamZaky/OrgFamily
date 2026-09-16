import 'package:drift/drift.dart';

import '../../core/permissions/family_permissions.dart';
import '../local/database.dart';
import '../local/tables/family_members_table.dart';
import '../local/tables/sync_outbox_table.dart';
import '../sync/sync_engine.dart';

class ShoppingRepository {
  ShoppingRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncEngine _sync;

  Stream<List<ShoppingList>> watchLists() {
    return (_db.select(_db.shoppingLists)
          ..where((l) => l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
        .watch();
  }

  /// Seeds the default category lists (Grocery, Vacation packing, etc.) the
  /// first time the app runs — a no-op once any list exists, so it never
  /// resurrects lists the user has deleted. Deliberately checks *all* rows,
  /// including soft-deleted ones (unlike every other query here) — a
  /// family that once had lists and deleted them all should still never see
  /// them reseeded.
  Future<void> seedDefaultCategoriesIfEmpty() async {
    final hasAnyList = await (_db.select(_db.shoppingLists)..limit(1)).get();
    if (hasAnyList.isNotEmpty) return;
    final now = DateTime.now();
    await _db.batch((b) {
      b.insertAll(_db.shoppingLists, [
        for (final (id, name, emoji) in defaultShoppingCategories)
          ShoppingListsCompanion.insert(
            id: id,
            name: name,
            emoji: Value(emoji),
            updatedAt: Value(now),
          ),
      ]);
    });
  }

  Stream<List<ShoppingItem>> watchItems(String listId) {
    return (_db.select(_db.shoppingItems)
          ..where((i) => i.listId.equals(listId) & i.deletedAt.isNull())
          ..orderBy([
            (i) => OrderingTerm.asc(i.isPurchased),
            (i) => OrderingTerm.asc(i.createdAt),
          ]))
        .watch();
  }

  Future<void> addList({
    required String id,
    required String name,
    String emoji = '🛒',
    FamilyRole actingRole = FamilyRole.owner,
  }) {
    if (!canPerform(actingRole, FamilyAction.manageLists)) {
      throw FamilyPermissionException(FamilyAction.manageLists, actingRole);
    }
    return _db.transaction(() async {
      await _db.into(_db.shoppingLists).insert(
            ShoppingListsCompanion.insert(
              id: id,
              name: name,
              emoji: Value(emoji),
              updatedAt: Value(DateTime.now()),
            ),
          );
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.shoppingList, entityId: id);
    });
  }

  /// Soft-deletes the list and every item under it (see tasks_table.dart's
  /// deletedAt doc comment) — the SQL cascade on [ShoppingItems.listId]
  /// never fires here since no row is actually removed, so items are
  /// tombstoned explicitly instead.
  Future<void> deleteList(String id, {FamilyRole actingRole = FamilyRole.owner}) {
    if (!canPerform(actingRole, FamilyAction.manageLists)) {
      throw FamilyPermissionException(FamilyAction.manageLists, actingRole);
    }
    final now = DateTime.now();
    return _db.transaction(() async {
      final itemIds = await (_db.selectOnly(_db.shoppingItems)
            ..addColumns([_db.shoppingItems.id])
            ..where(_db.shoppingItems.listId.equals(id)))
          .map((row) => row.read(_db.shoppingItems.id)!)
          .get();
      await (_db.update(_db.shoppingLists)..where((l) => l.id.equals(id)))
          .write(ShoppingListsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await (_db.update(_db.shoppingItems)..where((i) => i.listId.equals(id)))
          .write(ShoppingItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.shoppingList, entityId: id);
      for (final itemId in itemIds) {
        await _sync.enqueueUpsert(db: _db, type: SyncEntityType.shoppingItem, entityId: itemId);
      }
    });
  }

  Future<void> addItem({
    required String id,
    required String listId,
    required String name,
    String? quantity,
    String? addedById,
    FamilyRole actingRole = FamilyRole.owner,
  }) {
    if (!canPerform(actingRole, FamilyAction.addListItem)) {
      throw FamilyPermissionException(FamilyAction.addListItem, actingRole);
    }
    return _db.transaction(() async {
      await _db.into(_db.shoppingItems).insert(
            ShoppingItemsCompanion.insert(
              id: id,
              listId: listId,
              name: name,
              quantity: Value(quantity),
              addedById: Value(addedById),
              updatedAt: Value(DateTime.now()),
            ),
          );
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.shoppingItem, entityId: id);
    });
  }

  Future<void> setPurchased(String id, bool isPurchased) {
    return _db.transaction(() async {
      await (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id))).write(
        ShoppingItemsCompanion(
          isPurchased: Value(isPurchased),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.shoppingItem, entityId: id);
    });
  }

  /// Soft-delete (see tasks_table.dart's deletedAt doc comment).
  Future<void> deleteItem(String id) {
    final now = DateTime.now();
    return _db.transaction(() async {
      await (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id)))
          .write(ShoppingItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      await _sync.enqueueUpsert(db: _db, type: SyncEntityType.shoppingItem, entityId: id);
    });
  }
}
