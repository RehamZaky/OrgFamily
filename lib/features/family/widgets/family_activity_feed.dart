import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/activity/activity_log.dart';
import '../../../data/local/database.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/activity_providers.dart';
import '../providers/family_providers.dart';

/// The sentence after the member's name, e.g. `completed "Feed the cat"`.
/// Built from the entry's own metadata — the names as they were then — so
/// it still reads right after the task is renamed or deleted.
String activityText(
  ActivityItem item,
  AppLocalizations l10n,
  Map<String, FamilyMember> membersById,
) {
  String m(String key) => item.metadata[key] as String? ?? '';
  return switch (item.type) {
    ActivityTypes.taskCreated => l10n.activityTaskCreated(m('title')),
    ActivityTypes.taskAssigned => l10n.activityTaskAssigned(
      m('title'),
      membersById[item.metadata['assigneeId']]?.name ?? l10n.activitySomeone,
    ),
    ActivityTypes.taskCompleted => l10n.activityCompleted(m('title')),
    ActivityTypes.eventCreated => l10n.activityEventCreated(m('title')),
    ActivityTypes.eventChanged => l10n.activityEventChanged(m('title')),
    ActivityTypes.eventCancelled => l10n.activityEventCancelled(m('title')),
    ActivityTypes.shoppingItemAdded => l10n.activityAdded(m('name'), m('listName')),
    ActivityTypes.shoppingItemPurchased => l10n.activityItemBought(m('name')),
    ActivityTypes.shoppingItemRemoved => l10n.activityItemRemoved(m('name'), m('listName')),
    ActivityTypes.memberJoined => l10n.activityMemberJoined,
    ActivityTypes.responsibilityCompleted => l10n.activityResponsibilityDone(m('title')),
    _ => '',
  };
}

(IconData, Color) activityIcon(ActivityItem item, AppColorScheme colors) => switch (item.type) {
  ActivityTypes.taskCompleted ||
  ActivityTypes.responsibilityCompleted => (Icons.check_circle, colors.success),
  ActivityTypes.taskCreated => (Icons.add_task, colors.accent),
  ActivityTypes.taskAssigned => (Icons.assignment_ind, colors.accent),
  ActivityTypes.eventCreated || ActivityTypes.eventChanged => (Icons.event, colors.warning),
  ActivityTypes.eventCancelled => (Icons.event_busy, colors.danger),
  ActivityTypes.shoppingItemAdded => (Icons.add_shopping_cart, colors.accent),
  ActivityTypes.shoppingItemPurchased => (Icons.shopping_bag, colors.success),
  ActivityTypes.shoppingItemRemoved => (Icons.remove_shopping_cart, colors.danger),
  ActivityTypes.memberJoined => (Icons.waving_hand, colors.warning),
  _ => (Icons.circle, colors.textSecondary),
};

String timeAgo(BuildContext context, AppLocalizations l10n, DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.justNow;
  if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
  final locale = Localizations.localeOf(context).toString();
  return DateFormat('MMM d', locale).format(dt);
}

class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.item, required this.membersById, this.timeLabel});

  final ActivityItem item;
  final Map<String, FamilyMember> membersById;

  /// Shown under the sentence; defaults to "5 minutes ago" style.
  final String? timeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final member = membersById[item.memberId];
    final (icon, iconColor) = activityIcon(item, context.colors);
    // A member who has since been removed keeps their name on the entries
    // that recorded it.
    final name = member?.name ?? (item.metadata['name'] as String?);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            MemberAvatar(member: member, radius: 18),
            PositionedDirectional(
              end: -2,
              bottom: -2,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: context.colors.surface,
                child: Icon(icon, size: 12, color: iconColor),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 13),
                  children: [
                    TextSpan(
                      text: item.type == ActivityTypes.memberJoined
                          ? (name ?? l10n.activitySomeone)
                          : (member?.name ?? l10n.activitySomeone),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' ${activityText(item, l10n, membersById)}'),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timeLabel ?? timeAgo(context, l10n, item.time),
                style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Members by id, for resolving who an entry is credited to.
Map<String, FamilyMember> membersByIdOf(WidgetRef ref) => {
  for (final m in ref.watch(familyMembersProvider).valueOrNull ?? <FamilyMember>[]) m.id: m,
};

/// The "Family Activity" card body on Home and the Family screen: the
/// latest [limit] entries of the last week, or an empty-state message.
class FamilyActivityFeed extends ConsumerWidget {
  const FamilyActivityFeed({super.key, this.limit = 4});

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membersById = membersByIdOf(ref);
    final activity = (ref.watch(familyActivityProvider(7)).valueOrNull ?? const <ActivityItem>[])
        .take(limit)
        .toList();

    if (activity.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            l10n.emptyNoActivityYet,
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < activity.length; i++) ...[
          ActivityRow(item: activity[i], membersById: membersById),
          if (i != activity.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}
