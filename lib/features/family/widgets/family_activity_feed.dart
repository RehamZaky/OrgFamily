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

/// The action, with [actor] wherever the language puts the name — English
/// leads with it ("Mariam completed a task"); Arabic uses a neutral passive
/// that fits every member without a gender ("تم إكمال مهمة بواسطة مريم").
/// The item itself goes on its own line (see [activityTitle]), so long or
/// Arabic titles don't make the sentence hard to scan.
String activityText(
  ActivityItem item,
  AppLocalizations l10n,
  Map<String, FamilyMember> membersById,
  String actor,
) {
  String m(String key) => item.metadata[key] as String? ?? '';
  return switch (item.type) {
    ActivityTypes.taskCreated => l10n.activityTaskCreated(actor),
    ActivityTypes.taskAssigned => l10n.activityTaskAssigned(
      actor,
      membersById[item.metadata['assigneeId']]?.name ?? l10n.activitySomeone,
    ),
    ActivityTypes.taskCompleted => l10n.activityCompleted(actor),
    ActivityTypes.eventCreated => l10n.activityEventCreated(actor),
    ActivityTypes.eventChanged => l10n.activityEventChanged(actor),
    ActivityTypes.eventCancelled => l10n.activityEventCancelled(actor),
    ActivityTypes.shoppingItemAdded => l10n.activityAdded(actor, m('listName')),
    ActivityTypes.shoppingItemPurchased => l10n.activityItemBought(actor),
    ActivityTypes.shoppingItemRemoved => l10n.activityItemRemoved(actor, m('listName')),
    ActivityTypes.memberJoined => l10n.activityMemberJoined(actor),
    ActivityTypes.responsibilityCompleted => l10n.activityResponsibilityDone(actor),
    _ => '',
  };
}

/// What the entry is about — the task/event/chore title or item name as it
/// was then, so it still reads right after a rename or delete. Null when
/// the action says it all (a member joining).
String? activityTitle(ActivityItem item) {
  if (item.type == ActivityTypes.memberJoined) return null;
  final title = (item.metadata['title'] ?? item.metadata['name']) as String?;
  return (title == null || title.isEmpty) ? null : title;
}

/// [activityText] as spans, with the actor's name in bold.
List<TextSpan> activitySpans(
  ActivityItem item,
  AppLocalizations l10n,
  Map<String, FamilyMember> membersById,
  String actor,
) {
  const marker = '\u0001';
  final parts = activityText(item, l10n, membersById, marker).split(marker);
  return [
    for (var i = 0; i < parts.length; i++) ...[
      if (i > 0) TextSpan(text: actor, style: const TextStyle(fontWeight: FontWeight.w700)),
      if (parts[i].isNotEmpty) TextSpan(text: parts[i]),
    ],
  ];
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
  return DateFormat('MMM d', locale).format(dt.toLocal());
}

class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.item, required this.membersById, this.timeLabel});

  final ActivityItem item;
  final Map<String, FamilyMember> membersById;

  /// Shown at the end of the first line; defaults to "5 minutes ago" style.
  final String? timeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final member = membersById[item.memberId];
    final (icon, iconColor) = activityIcon(item, colors);
    // A member who has since been removed: a join entry still has the name
    // it recorded (other entries' `name` is an item's, not a person's).
    final actor =
        member?.name ??
        (item.type == ActivityTypes.memberJoined ? item.metadata['name'] as String? : null) ??
        l10n.activitySomeone;
    final title = activityTitle(item);
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
                backgroundColor: colors.surface,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                        children: activitySpans(item, l10n, membersById, actor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      timeLabel ?? timeAgo(context, l10n, item.time),
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
              if (title != null) ...[
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
          child: Text(l10n.emptyNoActivityYet, style: TextStyle(color: context.colors.textSecondary)),
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
