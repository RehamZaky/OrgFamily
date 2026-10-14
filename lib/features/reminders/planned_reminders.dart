import '../../core/notifications/notification_service.dart';
import '../../data/local/database.dart';
import '../../l10n/app_localizations.dart';
import '../family/daily_responsibility_reminders.dart';
import '../tasks/domain/task_status_calculator.dart';

/// What a planned reminder is for — also what opens when it's tapped.
enum PlannedReminderKind { task, event, responsibilities }

/// One notification this phone has planned (V2.3, My reminders).
class PlannedReminder {
  const PlannedReminder({
    required this.kind,
    required this.entityId,
    required this.title,
    required this.at,
    required this.memberIds,
    required this.isMine,
    this.body,
  });

  final PlannedReminderKind kind;

  /// The task or event id; for the daily responsibilities reminder, its
  /// day's slot (one notification id per slot, see `NotificationService`).
  final String entityId;
  final String title;
  final String? body;
  final DateTime at;

  /// Who it concerns: the task's assignee, the event's members — empty for
  /// an unassigned task or a whole-family event.
  final List<String> memberIds;

  /// Shown under "Mine": the phone owner's own, or the whole family's.
  final bool isMine;
}

/// Everything [planPhoneReminders] needs, read from the database and this
/// phone's settings.
class PhoneReminderInputs {
  const PhoneReminderInputs({
    required this.ownerId,
    required this.tasks,
    required this.events,
    required this.eventMembers,
    required this.eventMinutesBefore,
    required this.dailyAtMinutes,
    required this.ownerResponsibilities,
    required this.schoolDays,
  });

  /// The phone's own person — the signed-in adult's linked profile (see
  /// `reminderOwnerProvider`), never the acting profile.
  final String? ownerId;
  final List<Task> tasks;
  final List<Event> events;

  /// Event id → member ids (see `EventRepository.watchAllEventMembers`).
  final Map<String, List<String>> eventMembers;

  /// This phone's "event reminder" setting; null = none.
  final int? eventMinutesBefore;

  /// The owner's daily responsibilities reminder time; null = off.
  final int? dailyAtMinutes;
  final List<Responsibility> ownerResponsibilities;
  final Set<int> schoolDays;
}

/// The reminders this phone will ring for, from now until the end of the
/// [days]-th day (today counts as the first), soonest first.
///
/// Built from the same rules that schedule them — [taskNotificationAt],
/// [eventNotificationAt] and [planDailyResponsibilityReminders] — over the
/// same records: every task and event in the family (each phone schedules
/// them all), and the owner's daily reminder. A time already past is
/// skipped, as `NotificationService` never schedules one. A notification
/// is addressed by its entity (or slot), so each appears at most once.
List<PlannedReminder> planPhoneReminders(
  PhoneReminderInputs inputs, {
  required DateTime now,
  required AppLocalizations l10n,
  int days = 7,
}) {
  final end = DateTime(now.year, now.month, now.day + days);
  bool inWindow(DateTime? at) => at != null && at.isAfter(now) && at.isBefore(end);
  final owner = inputs.ownerId;
  final byKey = <(PlannedReminderKind, String), PlannedReminder>{};
  void add(PlannedReminder r) => byKey.putIfAbsent((r.kind, r.entityId), () => r);

  for (final t in inputs.tasks) {
    if (t.deletedAt != null) continue;
    final at = taskNotificationAt(TaskReminderInput.fromTask(t));
    if (!inWindow(at)) continue;
    add(PlannedReminder(
      kind: PlannedReminderKind.task,
      entityId: t.id,
      title: t.title,
      at: at!,
      memberIds: [?t.assigneeId],
      // Unassigned tasks are the whole family's.
      isMine: t.assigneeId == null || t.assigneeId == owner,
    ));
  }

  for (final e in inputs.events) {
    if (e.deletedAt != null) continue;
    final at = eventNotificationAt(e.startAt, inputs.eventMinutesBefore);
    if (!inWindow(at)) continue;
    final members = inputs.eventMembers[e.id] ?? const <String>[];
    add(PlannedReminder(
      kind: PlannedReminderKind.event,
      entityId: e.id,
      title: e.title,
      at: at!,
      memberIds: members,
      // No members = a whole-family event; otherwise one the owner is in.
      isMine: members.isEmpty || members.contains(owner),
    ));
  }

  final dailyAt = inputs.dailyAtMinutes;
  if (owner != null && dailyAt != null) {
    for (final plan in planDailyResponsibilityReminders(
      now: now,
      atMinutes: dailyAt,
      responsibilities: inputs.ownerResponsibilities,
      schoolDays: inputs.schoolDays,
      l10n: l10n,
      days: days,
    )) {
      add(PlannedReminder(
        kind: PlannedReminderKind.responsibilities,
        entityId: '${plan.slot}',
        title: l10n.homeMyResponsibilities,
        body: plan.body,
        at: plan.at,
        memberIds: [owner],
        isMine: true,
      ));
    }
  }

  return byKey.values.toList()
    ..sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      return byTime != 0 ? byTime : a.title.compareTo(b.title);
    });
}

/// [reminders] (already in time order) in one group per local day, in
/// order — the screen labels each day Today / Tomorrow / weekday.
List<(DateTime day, List<PlannedReminder> reminders)> groupRemindersByDay(
  List<PlannedReminder> reminders,
) {
  final groups = <(DateTime, List<PlannedReminder>)>[];
  for (final r in reminders) {
    final day = DateTime(r.at.year, r.at.month, r.at.day);
    if (groups.isEmpty || groups.last.$1 != day) groups.add((day, []));
    groups.last.$2.add(r);
  }
  return groups;
}
