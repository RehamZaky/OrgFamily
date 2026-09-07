import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/local/database.dart';
import '../../../l10n/app_localizations.dart';
import '../../shopping/providers/shopping_providers.dart';
import '../providers/family_providers.dart';

class ActivityEntry {
  ActivityEntry({
    required this.member,
    required this.text,
    required this.time,
    required this.icon,
    required this.iconColor,
  });

  final FamilyMember? member;
  final String text;
  final DateTime time;
  final IconData icon;
  final Color iconColor;
}

/// Merges completed tasks and newly added shopping items into one
/// time-sorted feed — the "Family Activity" data, shared by the Home
/// dashboard and Family screen.
List<ActivityEntry> buildFamilyActivity({
  required List<Task> tasks,
  required List<ShoppingList> lists,
  required Map<String, FamilyMember> membersById,
  required WidgetRef ref,
  required AppLocalizations l10n,
  int limit = 4,
}) {
  final entries = <ActivityEntry>[];
  for (final t in tasks) {
    if (t.isCompleted && t.completedAt != null) {
      entries.add(ActivityEntry(
        member: membersById[t.assigneeId],
        text: l10n.activityCompleted(t.title),
        time: t.completedAt!,
        icon: Icons.check_circle,
        iconColor: AppColors.success,
      ));
    }
  }
  for (final list in lists) {
    final items = ref.watch(shoppingItemsProvider(list.id)).valueOrNull ?? [];
    for (final item in items) {
      entries.add(ActivityEntry(
        member: membersById[item.addedById],
        text: l10n.activityAdded(item.name, list.name),
        time: item.createdAt,
        icon: Icons.add_circle,
        iconColor: AppColors.primary,
      ));
    }
  }
  entries.sort((a, b) => b.time.compareTo(a.time));
  return entries.take(limit).toList();
}

String _timeAgo(BuildContext context, AppLocalizations l10n, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.justNow;
  if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
  final locale = Localizations.localeOf(context).toString();
  return DateFormat('MMM d', locale).format(dt);
}

class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            MemberAvatar(member: entry.member, radius: 18),
            Positioned(
              right: -2,
              bottom: -2,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.white,
                child: Icon(entry.icon, size: 12, color: entry.iconColor),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 13),
                  children: [
                    TextSpan(
                      text: entry.member?.name ?? l10n.activitySomeone,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' ${entry.text}'),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(_timeAgo(context, l10n, entry.time),
                  style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The "Family Activity" card body: recent task completions and shopping
/// additions, merged and sorted by time, or an empty-state message.
class FamilyActivityFeed extends ConsumerWidget {
  const FamilyActivityFeed({
    super.key,
    required this.tasks,
    required this.lists,
    this.limit = 4,
  });

  final List<Task> tasks;
  final List<ShoppingList> lists;
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membersById = <String, FamilyMember>{
      for (final m in ref.watch(familyMembersProvider).valueOrNull ?? [])
        m.id: m
    };
    final activity = buildFamilyActivity(
      tasks: tasks,
      lists: lists,
      membersById: membersById,
      ref: ref,
      l10n: l10n,
      limit: limit,
    );

    if (activity.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(l10n.emptyNoActivityYet,
              style: TextStyle(color: context.colors.textSecondary)),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < activity.length; i++) ...[
          ActivityRow(entry: activity[i]),
          if (i != activity.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}
