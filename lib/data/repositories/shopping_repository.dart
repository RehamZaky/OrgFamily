import 'package:drift/drift.dart';

import '../../core/permissions/family_permissions.dart';
import '../local/database.dart';
import '../local/tables/family_members_table.dart';

class ShoppingRepository {
  ShoppingRepository(this._db);

  final AppDatabase _db;

  Stream<List<ShoppingList>> watchLists() {
    return (_db.select(_db.shoppingLists)
          ..orderBy([(l) => OrderingTerm.asc(l.createdAt)]))
        .watch();
  }

  /// Seeds the default category lists (Grocery, Vacation packing, etc.) the
  /// first time the app runs — a no-op once any list exists, so it never
  /// resurrects lists the user has deleted.
  Future<void> seedDefaultCategoriesIfEmpty() async {
    final hasAnyList = await (_db.select(_db.shoppingLists)..limit(1)).get();
    if (hasAnyList.isNotEmpty) return;
    await _db.batch((b) {
      b.insertAll(_db.shoppingLists, [
        for (final (id, name, emoji) in defaultShoppingCategories)
          ShoppingListsCompanion.insert(id: id, name: name, emoji: Value(emoji)),
      ]);
    });
  }

  Stream<List<ShoppingItem>> watchItems(String listId) {
    return (_db.select(_db.shoppingItems)
          ..where((i) => i.listId.equals(listId))
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
    return _db.into(_db.shoppingLists).insert(
          ShoppingListsCompanion.insert(
            id: id,
            name: name,
            emoji: Value(emoji),
          ),
        );
  }

  Future<void> deleteList(String id, {FamilyRole actingRole = FamilyRole.owner}) {
    if (!canPerform(actingRole, FamilyAction.manageLists)) {
      throw FamilyPermissionException(FamilyAction.manageLists, actingRole);
    }
    return (_db.delete(_db.shoppingLists)..where((l) => l.id.equals(id))).go();
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
    return _db.into(_db.shoppingItems).insert(
          ShoppingItemsCompanion.insert(
            id: id,
            listId: listId,
            name: name,
            quantity: Value(quantity),
            addedById: Value(addedById),
          ),
        );
  }

  Future<void> setPurchased(String id, bool isPurchased) {
    return (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id)))
        .write(ShoppingItemsCompanion(isPurchased: Value(isPurchased)));
  }

  Future<void> deleteItem(String id) {
    return (_db.delete(_db.shoppingItems)..where((i) => i.id.equals(id))).go();
  }
}
