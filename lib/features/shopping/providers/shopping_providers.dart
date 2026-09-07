import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../../data/providers.dart';

final shoppingListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  return ref.watch(shoppingRepositoryProvider).watchLists();
});

final shoppingItemsProvider =
    StreamProvider.family<List<ShoppingItem>, String>((ref, listId) {
  return ref.watch(shoppingRepositoryProvider).watchItems(listId);
});

/// Total pending (not-yet-purchased) items across all lists — used on the
/// dashboard preview.
final pendingShoppingItemCountProvider = Provider<int>((ref) {
  final lists = ref.watch(shoppingListsProvider).valueOrNull ?? [];
  var count = 0;
  for (final list in lists) {
    final items = ref.watch(shoppingItemsProvider(list.id)).valueOrNull ?? [];
    count += items.where((i) => !i.isPurchased).length;
  }
  return count;
});
