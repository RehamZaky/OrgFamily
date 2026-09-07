import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/option_picker_sheet.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';
import '../providers/shopping_providers.dart';

/// Add-item form, redesigned to match the "Add Item" mockup — but scoped
/// down to just the item name and the target list (no category, quantity,
/// priority, or notes fields, which weren't asked for).
class AddShoppingItemScreen extends ConsumerStatefulWidget {
  const AddShoppingItemScreen({super.key, this.initialListId});

  /// Pre-selects a list (e.g. opened from within that list's detail
  /// screen). Left null when opened from Quick Add, where the picker
  /// defaults to the first list.
  final String? initialListId;

  @override
  ConsumerState<AddShoppingItemScreen> createState() =>
      _AddShoppingItemScreenState();
}

class _AddShoppingItemScreenState extends ConsumerState<AddShoppingItemScreen> {
  final _nameController = TextEditingController();
  String? _selectedListId;

  @override
  void initState() {
    super.initState();
    _selectedListId = widget.initialListId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickList(List<ShoppingList> lists) async {
    final selected = lists.where((l) => l.id == _selectedListId).firstOrNull;
    final result = await showOptionPickerSheet<ShoppingList>(
      context: context,
      title: AppLocalizations.of(context)!.addItemAddToListLabel,
      options: lists,
      labelBuilder: (l) => l.name,
      selected: selected,
    );
    if (result != null) setState(() => _selectedListId = result.id);
  }

  Future<void> _save(List<ShoppingList> lists) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(shoppingRepositoryProvider);
    var listId = _selectedListId ?? (lists.isNotEmpty ? lists.first.id : null);
    if (listId == null) {
      listId = const Uuid().v4();
      await repo.addList(id: listId, name: 'Shopping', emoji: '🛒');
    }

    final me = ref.read(currentMemberProvider);
    await repo.addItem(
      id: const Uuid().v4(),
      listId: listId,
      name: name,
      addedById: me?.id,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lists = ref.watch(shoppingListsProvider).valueOrNull ?? [];
    final selectedList = lists.where((l) => l.id == _selectedListId).firstOrNull ??
        (lists.isNotEmpty ? lists.first : null);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(l10n.addItemScreenTitle),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _save(lists),
            child: Text(l10n.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(l10n.addItemNameLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.addItemNameHint,
              prefixIcon: const Icon(Icons.shopping_bag_outlined),
            ),
            onSubmitted: (_) => _save(lists),
          ),
          const SizedBox(height: 24),
          Text(l10n.addItemAddToListLabel,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PickerRow(
              icon: Icons.list_alt_outlined,
              iconColor: AppColors.primary,
              label: l10n.addItemAddToListLabel,
              value: selectedList == null
                  ? l10n.addItemNewListValue
                  : '${selectedList.emoji}  ${selectedList.name}',
              onTap: () => _pickList(lists),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _save(lists),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l10n.addItemButtonLabel),
          ),
        ],
      ),
    );
  }
}
