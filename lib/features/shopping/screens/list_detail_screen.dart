import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';
import '../../family/providers/family_providers.dart';
import '../providers/shopping_providers.dart';

class ListDetailScreen extends ConsumerStatefulWidget {
  const ListDetailScreen({super.key, required this.list});

  final ShoppingList list;

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  final _itemController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _itemController.text.trim();
    if (name.isEmpty) return;
    final me = ref.read(currentMemberProvider);
    await ref.read(shoppingRepositoryProvider).addItem(
          id: const Uuid().v4(),
          listId: widget.list.id,
          name: name,
          addedById: me?.id,
          actingRole: ref.read(activeRoleProvider),
        );
    _itemController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingItemsProvider(widget.list.id));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.list.emoji}  ${widget.list.name}')),
      body: Column(
        children: [
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text('No items yet',
                        style: TextStyle(color: context.colors.textSecondary)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete_outline,
                            color: AppColors.priorityHigh),
                      ),
                      onDismissed: (_) => ref
                          .read(shoppingRepositoryProvider)
                          .deleteItem(item.id),
                      child: CheckboxListTile(
                        value: item.isPurchased,
                        onChanged: (v) => ref
                            .read(shoppingRepositoryProvider)
                            .setPurchased(item.id, v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.success,
                        title: Text(
                          item.quantity == null
                              ? item.name
                              : '${item.name}  (${item.quantity})',
                          style: TextStyle(
                            decoration: item.isPurchased
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.isPurchased
                                ? context.colors.textSecondary
                                : context.colors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        hintText: 'Add an item',
                        filled: true,
                        fillColor: context.colors.surface,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addItem,
                    style: FilledButton.styleFrom(
                        shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
                    child: const Icon(Icons.save_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
