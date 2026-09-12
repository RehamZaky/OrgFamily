import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/permissions/active_profile_provider.dart';
import '../../../core/permissions/family_permissions.dart';
import '../../../core/permissions/permission_ui.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/list_icon.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/no_results_animation.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/shopping_providers.dart';
import 'list_detail_screen.dart';

const _listEmojis = ['🛒', '🏖️', '🏫', '🏠', '🎁', '🚗'];

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
    if (!checkPermission(context, ref, FamilyAction.manageLists)) return;
    final controller = TextEditingController();
    String emoji = _listEmojis.first;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New list'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'List name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _listEmojis.map((e) {
                  final selected = e == emoji;
                  final (icon, color) = listIconFor(e);
                  return GestureDetector(
                    onTap: () => setState(() => emoji = e),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          selected ? color.withValues(alpha: 0.2) : Colors.grey.shade100,
                      child: Icon(icon, color: color, size: 18),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(emoji),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    final name = controller.text.trim();
    if (result == null || name.isEmpty) return;
    await ref.read(shoppingRepositoryProvider).addList(
          id: const Uuid().v4(),
          name: name,
          emoji: result,
          actingRole: ref.read(activeRoleProvider),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final listsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n.navLists),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _createList(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.newList),
            ),
          ),
        ],
      ),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lists) {
          if (lists.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NoResultsAnimation(),
                    const Text('No lists yet', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Tap + New list to start a groceries, packing, or gift list.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.textSecondary)),
                  ],
                ),
              ),
            );
          }

          final query = _query.trim().toLowerCase();
          final filtered = query.isEmpty
              ? lists
              : lists.where((l) => l.name.toLowerCase().contains(query)).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l10n.listsSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: context.colors.surface,
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const NoResultsAnimation(),
                            Text(l10n.noListsMatch,
                                style: TextStyle(color: context.colors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final list = filtered[i];
                          final itemsAsync = ref.watch(shoppingItemsProvider(list.id));
                          final items = itemsAsync.valueOrNull ?? [];
                          final total = items.length;
                          final pending = items.where((it) => !it.isPurchased).length;
                          final done = total - pending;
                          final (icon, color) = listIconFor(list.emoji);

                          return Dismissible(
                            key: ValueKey(list.id),
                            direction: DismissDirection.startToEnd,
                            background: Container(
                              decoration: BoxDecoration(
                                color: AppColors.priorityHigh,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: AlignmentDirectional.centerStart,
                              padding: const EdgeInsetsDirectional.only(start: 20),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            confirmDismiss: (_) async =>
                                checkPermission(context, ref, FamilyAction.manageLists),
                            onDismissed: (_) =>
                                ref.read(shoppingRepositoryProvider).deleteList(
                                      list.id,
                                      actingRole: ref.read(activeRoleProvider),
                                    ),
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => ListDetailScreen(list: list)),
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: color.withValues(alpha: 0.15),
                                        child: Icon(icon, color: color, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(list.name,
                                                style:
                                                    const TextStyle(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(
                                              total == 0
                                                  ? l10n.emptyNoItemsYet
                                                  : l10n.itemsLeft(pending),
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.colors.textSecondary),
                                            ),
                                            if (total > 3) ...[
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(4),
                                                child: LinearProgressIndicator(
                                                  value: done / total,
                                                  minHeight: 5,
                                                  backgroundColor: color.withValues(alpha: 0.15),
                                                  valueColor:
                                                      AlwaysStoppedAnimation<Color>(color),
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                l10n.itemsCompleted(done, total),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: context.colors.textSecondary),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right,
                                          color: context.colors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
