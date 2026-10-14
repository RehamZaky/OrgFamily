import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/core/preferences/app_preferences.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/events_table.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/data/local/tables/responsibilities_table.dart';
import 'package:org_family/data/local/tables/tasks_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/family/daily_responsibility_reminders.dart';
import 'package:org_family/features/reminders/planned_reminders.dart';
import 'package:org_family/features/reminders/reminder_list_providers.dart';
import 'package:org_family/features/settings/providers/reminder_providers.dart';
import 'package:org_family/l10n/app_localizations.dart';

import '../fakes/fake_notification_service.dart';

// 2026-10-11 is a Sunday (a default school day).
final _now = DateTime(2026, 10, 11, 9);

Task _task(
  String id, {
  String? assignee,
  DateTime? due,
  int? dueTime,
  TaskReminderType type = TaskReminderType.dueTime,
  int? offset,
  DateTime? at,
  bool done = false,
  DateTime? deleted,
}) => Task(
  id: id,
  title: id,
  priority: TaskPriority.normal,
  category: TaskCategory.other,
  isCompleted: done,
  recurrence: TaskRecurrence.none,
  reminderType: type,
  reminderOffsetMinutes: offset,
  reminderAt: at,
  dueDate: due,
  dueTimeMinutes: dueTime,
  assigneeId: assignee,
  deletedAt: deleted,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Event _event(String id, DateTime start, {DateTime? deleted}) => Event(
  id: id,
  title: id,
  startAt: start,
  category: EventCategory.other,
  deletedAt: deleted,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Responsibility _chore(String id, {DateTime? done}) => Responsibility(
  id: id,
  memberId: 'me',
  title: id,
  recurrence: ResponsibilityRecurrence.daily,
  lastCompletedDate: done,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late AppLocalizations l10n;
  setUpAll(() async => l10n = await AppLocalizations.delegate.load(const Locale('en')));

  List<PlannedReminder> plan({
    List<Task> tasks = const [],
    List<Event> events = const [],
    Map<String, List<String>> eventMembers = const {},
    int? eventMinutes = 15,
    int? dailyAt,
    List<Responsibility> chores = const [],
    String? owner = 'me',
    DateTime? now,
  }) => planPhoneReminders(
    PhoneReminderInputs(
      ownerId: owner,
      tasks: tasks,
      events: events,
      eventMembers: eventMembers,
      eventMinutesBefore: eventMinutes,
      dailyAtMinutes: dailyAt,
      ownerResponsibilities: chores,
      schoolDays: const {7, 1, 2, 3, 4},
    ),
    now: now ?? _now,
    l10n: l10n,
  );

  List<String> ids(Iterable<PlannedReminder> rs) => [for (final r in rs) r.entityId];
  List<String> mine(Iterable<PlannedReminder> rs) => ids(rs.where((r) => r.isMine));

  group('filtering: Mine vs Everyone', () {
    test("tasks: mine and unassigned are Mine; someone else's only under Everyone", () {
      final today = DateTime(2026, 10, 11);
      final rs = plan(tasks: [
        _task('mine', assignee: 'me', due: today, dueTime: 18 * 60),
        _task('family', due: today, dueTime: 18 * 60 + 1),
        _task('omar', assignee: 'omar', due: today, dueTime: 18 * 60 + 2),
      ]);
      expect(ids(rs), ['mine', 'family', 'omar']);
      expect(mine(rs), ['mine', 'family']);
      expect(rs.firstWhere((r) => r.entityId == 'omar').memberIds, ['omar']);
    });

    test('events: whole-family and ones I attend are Mine; others only under Everyone', () {
      final rs = plan(
        events: [
          _event('family', DateTime(2026, 10, 11, 18)),
          _event('withMe', DateTime(2026, 10, 11, 19)),
          _event('notMe', DateTime(2026, 10, 11, 20)),
        ],
        eventMembers: {
          'withMe': ['me', 'omar'],
          'notMe': ['omar', 'mariam'],
        },
      );
      expect(ids(rs), ['family', 'withMe', 'notMe']);
      expect(mine(rs), ['family', 'withMe']);
      expect(rs.first.memberIds, isEmpty);
    });

    test("the daily reminder is the owner's, under Mine", () {
      final rs = plan(dailyAt: 19 * 60, chores: [_chore('Feed the cat')]);
      expect(rs, hasLength(7));
      expect(rs.every((r) => r.kind == PlannedReminderKind.responsibilities && r.isMine), isTrue);
      expect(rs.first.body, '1 responsibility left today 💜 Feed the cat');
      expect(rs.first.memberIds, ['me']);
    });

    test('no daily reminder without an owner or with the setting off', () {
      expect(plan(dailyAt: 19 * 60, chores: [_chore('x')], owner: null), isEmpty);
      expect(plan(chores: [_chore('x')]), isEmpty);
    });
  });

  group('same rules as the scheduler', () {
    final tomorrow = DateTime(2026, 10, 12);

    test('task reminder types: due time, 9 AM for date-only, offset, custom, none', () {
      final rs = plan(tasks: [
        _task('timed', due: tomorrow, dueTime: 17 * 60),
        _task('dateOnly', due: tomorrow),
        _task('offset', due: tomorrow, dueTime: 17 * 60, type: TaskReminderType.offset, offset: 30),
        _task('custom', due: tomorrow, type: TaskReminderType.custom, at: DateTime(2026, 10, 13, 7)),
        _task('none', due: tomorrow, dueTime: 17 * 60, type: TaskReminderType.none),
      ]);
      expect({for (final r in rs) r.entityId: r.at}, {
        'dateOnly': DateTime(2026, 10, 12, 9),
        'offset': DateTime(2026, 10, 12, 16, 30),
        'timed': DateTime(2026, 10, 12, 17),
        'custom': DateTime(2026, 10, 13, 7),
      });
    });

    test('completed, undated, deleted and past tasks are skipped', () {
      final rs = plan(tasks: [
        _task('done', due: tomorrow, dueTime: 600, done: true),
        _task('undated'),
        _task('deleted', due: tomorrow, dueTime: 600, deleted: _now),
        _task('past', due: DateTime(2026, 10, 11), dueTime: 8 * 60),
      ]);
      expect(rs, isEmpty);
    });

    test("events use this phone's offset; none means no event reminders", () {
      final events = [_event('e', DateTime(2026, 10, 11, 18))];
      expect(plan(events: events, eventMinutes: 60).single.at, DateTime(2026, 10, 11, 17));
      expect(plan(events: events, eventMinutes: 0).single.at, DateTime(2026, 10, 11, 18));
      expect(plan(events: events, eventMinutes: null), isEmpty);
      expect(plan(events: [_event('gone', DateTime(2026, 10, 11, 18), deleted: _now)]), isEmpty);
    });

    test('a daily reminder is skipped on a day everything is done', () {
      final rs = plan(dailyAt: 19 * 60, chores: [_chore('Feed the cat', done: _now)]);
      expect(rs.map((r) => r.at.day), isNot(contains(11)));
      expect(rs, hasLength(6));
    });

    test('7 days: today through the 6th day after, nothing later', () {
      final rs = plan(tasks: [
        _task('lastDay', due: DateTime(2026, 10, 17), dueTime: 23 * 60 + 59),
        _task('tooLate', due: DateTime(2026, 10, 18), dueTime: 0),
      ]);
      expect(ids(rs), ['lastDay']);
    });
  });

  group('duplicates', () {
    test('a task or event appears once however often it is listed', () {
      final t = _task('t', due: DateTime(2026, 10, 12), dueTime: 600);
      final e = _event('e', DateTime(2026, 10, 12, 12));
      final rs = plan(tasks: [t, t], events: [e, e]);
      expect(ids(rs), ['t', 'e']);
    });

    test('one daily reminder per day', () {
      final rs = plan(dailyAt: 19 * 60, chores: [_chore('a'), _chore('b'), _chore('c')]);
      expect(rs.map((r) => r.at).toSet(), hasLength(rs.length));
      expect(rs.map((r) => r.entityId).toSet(), hasLength(rs.length));
    });
  });

  group('date grouping', () {
    test('one group per day, in order, times sorted within', () {
      final rs = plan(
        tasks: [
          _task('tue', due: DateTime(2026, 10, 13), dueTime: 8 * 60),
          _task('sunLate', due: DateTime(2026, 10, 11), dueTime: 21 * 60),
          _task('sunEarly', due: DateTime(2026, 10, 11), dueTime: 10 * 60),
        ],
        events: [_event('mon', DateTime(2026, 10, 12, 12))],
      );
      final groups = groupRemindersByDay(rs);
      expect([for (final (day, _) in groups) day], [
        DateTime(2026, 10, 11),
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 13),
      ]);
      expect(ids(groups.first.$2), ['sunEarly', 'sunLate']);
      expect(groupRemindersByDay(const []), isEmpty);
    });
  });

  test('lists exactly what the scheduler scheduled on this phone', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final notifications = FakeNotificationService();
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
      notificationServiceProvider.overrideWithValue(notifications),
    ]);
    addTearDown(container.dispose);

    // Signed out: the phone's reminders are the family Owner's.
    await db.into(db.familyMembers).insert(FamilyMembersCompanion.insert(
      id: 'me',
      name: 'Kareem',
      colorValue: 0xFF7C4DFF,
      role: const Value(FamilyRole.owner),
    ));
    container
        .read(reminderPreferencesProvider('me').notifier)
        .set(const ReminderPreferences(taskDefault: 0, eventMinutes: 30, dailyAtMinutes: 23 * 60 + 59));
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    await db.into(db.tasks).insert(TasksCompanion.insert(
      id: 't-mine',
      title: 'Mine',
      assigneeId: const Value('me'),
      dueDate: Value(DateTime(day.year, day.month, day.day + 2)),
      dueTimeMinutes: const Value(18 * 60),
    ));
    await db.into(db.tasks).insert(TasksCompanion.insert(
      id: 't-later',
      title: 'Next month',
      dueDate: Value(DateTime(day.year, day.month, day.day + 30)),
    ));
    await db.into(db.events).insert(EventsCompanion.insert(
      id: 'e-1',
      title: 'Dentist',
      startAt: DateTime(day.year, day.month, day.day + 3, 10),
    ));
    await db.into(db.responsibilities).insert(ResponsibilitiesCompanion.insert(
      id: 'r-1',
      memberId: 'me',
      title: 'Feed the cat',
      recurrence: const Value(ResponsibilityRecurrence.daily),
    ));

    // As in the app: scheduling reads the owner's settings once loaded.
    await _settled(container);
    expect(container.read(reminderOwnerProvider)?.id, 'me');
    await container.read(taskRepositoryProvider).resyncReminders();
    await container.read(eventRepositoryProvider).resyncReminders();
    await container.read(dailyResponsibilityRemindersProvider).replan(now: now);

    final inputs = await _settled(container);
    final planned = planPhoneReminders(inputs, now: now, l10n: l10n);
    final end = DateTime(day.year, day.month, day.day + 7);
    bool soon(DateTime at) => at.isAfter(now) && at.isBefore(end);
    expect(
      {for (final r in planned) '${r.kind.name}:${r.at}'},
      {
        for (final at in notifications.taskReminders.values) if (soon(at)) 'task:$at',
        for (final at in notifications.eventReminderTimes.values) if (soon(at)) 'event:$at',
        for (final d in notifications.dailyReminders.values) 'responsibilities:${d.at}',
      },
    );
    expect(planned, isNotEmpty);
  });
}

Future<PhoneReminderInputs> _settled(ProviderContainer container) async {
  final sub = container.listen(phoneReminderInputsProvider, (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 50; i++) {
    final v = sub.read();
    if (v.hasValue) return v.requireValue;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw StateError('reminder inputs never loaded');
}
