import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/activity/activity_log.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/responsibilities_table.dart';
import 'package:org_family/data/local/tables/sync_outbox_table.dart';
import 'package:org_family/data/local/tables/tasks_table.dart';
import 'package:org_family/data/repositories/responsibility_repository.dart';
import 'package:org_family/data/repositories/task_repository.dart';
import 'package:org_family/data/sync/adapters/activity_sync_adapter.dart';
import 'package:org_family/data/sync/adapters/responsibility_sync_adapter.dart';
import 'package:org_family/data/sync/adapters/task_sync_adapter.dart';
import 'package:org_family/data/sync/sync_engine.dart';

import '../fakes/fake_notification_service.dart';

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

const _familyId = 'fam-1';

/// One phone: its own database, sync engine and repositories, sharing the
/// test's (fake) Firestore with any other phone.
class _Phone {
  _Phone(FirebaseFirestore firestore, {required this.uid, DateTime Function()? clock})
    : db = AppDatabase.forTesting(NativeDatabase.memory()) {
    activityAdapter = _FlakyActivityAdapter(db);
    engine = SyncEngine(db, firestore, [
      TaskSyncAdapter(db),
      ResponsibilitySyncAdapter(db),
      activityAdapter,
    ]);
    log = ActivityLog(engine)..setActor(uid: uid, memberId: null);
    tasks = TaskRepository(db, FakeNotificationService(), engine, activity: log);
    chores = ResponsibilityRepository(db, engine, activity: log, clock: clock);
  }

  final String uid;
  final AppDatabase db;
  late final _FlakyActivityAdapter activityAdapter;
  late final SyncEngine engine;
  late final ActivityLog log;
  late final TaskRepository tasks;
  late final ResponsibilityRepository chores;

  Future<void> link() => db
      .into(db.familyProfile)
      .insertOnConflictUpdate(
        FamilyProfileCompanion.insert(
          id: const Value(1),
          familyId: const Value(_familyId),
          initialCloudMigrationCompletedAt: Value(DateTime(2024)),
        ),
      );

  Future<void> startSync() async {
    await link();
    engine.start(_familyId, uid);
    await _settle();
  }

  /// Every queued row due now, and drain.
  Future<void> reconnect() async {
    await db.update(db.syncOutbox).write(const SyncOutboxCompanion(nextRetryAt: Value(null)));
    await engine.drainNow();
    await _settle();
  }

  Future<List<FamilyActivity>> entries([String? type]) async {
    final rows = await db.select(db.familyActivities).get();
    return [
      for (final r in rows)
        if (type == null || r.type == type) r,
    ];
  }

  Future<void> close() async {
    engine.stop();
    await db.close();
  }
}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() => firestore = FakeFirebaseFirestore());

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> cloud([String? type]) async {
    final docs = (await firestore.collection('families/$_familyId/activities').get()).docs;
    return [
      for (final d in docs)
        if (type == null || d.data()['type'] == type) d,
    ];
  }

  group('responsibilities: one completion entry per responsibility per day', () {
    var now = DateTime(2026, 10, 11, 9);
    late _Phone phone;

    setUp(() async {
      now = DateTime(2026, 10, 11, 9);
      phone = _Phone(firestore, uid: 'uid-kareem', clock: () => now);
      await phone.chores.addResponsibility(
        id: 'r1',
        memberId: 'm-mariam',
        title: 'Organize the family',
        recurrence: ResponsibilityRecurrence.daily,
      );
    });
    tearDown(() => phone.close());

    test('untick and re-tick the same day: still one entry', () async {
      await phone.chores.setCompletedToday('r1', true);
      now = now.add(const Duration(minutes: 1));
      await phone.chores.setCompletedToday('r1', false);
      await phone.chores.setCompletedToday('r1', true);
      now = now.add(const Duration(hours: 5));
      await phone.chores.setCompletedToday('r1', false);
      await phone.chores.setCompletedToday('r1', true);

      final rows = await phone.entries(ActivityTypes.responsibilityCompleted);
      expect(rows.map((r) => r.id), ['responsibility.completed:r1:2026-10-11']);
    });

    test('the next scheduled day records a new entry', () async {
      await phone.chores.setCompletedToday('r1', true);
      now = DateTime(2026, 10, 12, 8);
      await phone.chores.setCompletedToday('r1', true);
      final ids = (await phone.entries(ActivityTypes.responsibilityCompleted)).map((r) => r.id);
      expect(ids.toSet(), {
        'responsibility.completed:r1:2026-10-11',
        'responsibility.completed:r1:2026-10-12',
      });
    });

    test('synced: re-ticking uploads nothing more', () async {
      await phone.startSync();
      await phone.chores.setCompletedToday('r1', true);
      await phone.chores.setCompletedToday('r1', false);
      await phone.chores.setCompletedToday('r1', true);
      await _settle();
      expect((await cloud(ActivityTypes.responsibilityCompleted)).map((d) => d.id), [
        'responsibility.completed:r1:2026-10-11',
      ]);
      expect(await phone.db.select(phone.db.syncOutbox).get(), isEmpty);
    });
  });

  group('entries from before deterministic ids (or an older build)', () {
    var now = DateTime(2026, 10, 11, 14, 45);
    late _Phone phone;

    /// A completion as the previous build stored it: a random id.
    Future<void> legacy(String type, String entityId, DateTime at) => phone.db
        .into(phone.db.familyActivities)
        .insert(
          FamilyActivitiesCompanion.insert(
            id: 'random-${at.millisecondsSinceEpoch}',
            type: type,
            entityType: type.startsWith('task') ? 'task' : 'responsibility',
            entityId: entityId,
            createdAt: at,
            occurredAt: Value(at.toUtc()),
            updatedAt: at,
          ),
        );

    setUp(() async {
      now = DateTime(2026, 10, 11, 14, 45);
      phone = _Phone(firestore, uid: 'uid-kareem', clock: () => now);
      await phone.chores.addResponsibility(
        id: 'r1',
        memberId: 'm-kareem',
        title: 'Organize the family',
        recurrence: ResponsibilityRecurrence.daily,
      );
    });
    tearDown(() => phone.close());

    test("a responsibility already completed today (old id) isn't recorded again", () async {
      // This morning, on the previous build — then unticked since.
      await legacy(ActivityTypes.responsibilityCompleted, 'r1', DateTime(2026, 10, 11, 12, 3));
      await phone.chores.setCompletedToday('r1', true);
      final rows = await phone.entries(ActivityTypes.responsibilityCompleted);
      expect(rows.map((r) => r.id), ['random-${DateTime(2026, 10, 11, 12, 3).millisecondsSinceEpoch}']);
    });

    test("yesterday's old-id completion doesn't block today's", () async {
      await legacy(ActivityTypes.responsibilityCompleted, 'r1', DateTime(2026, 10, 10, 20));
      await phone.chores.setCompletedToday('r1', true);
      final ids = (await phone.entries(ActivityTypes.responsibilityCompleted)).map((r) => r.id);
      expect(ids, contains('responsibility.completed:r1:2026-10-11'));
      expect(ids, hasLength(2));
    });

    test("a task completed under an old id isn't recorded again", () async {
      await phone.tasks.addTask(id: 't1', title: 'Call mom');
      await legacy(ActivityTypes.taskCompleted, 't1', DateTime(2026, 10, 11, 12, 28));
      await phone.tasks.setCompleted('t1', true);
      expect(await phone.entries(ActivityTypes.taskCompleted), hasLength(1));
    });
  });

  group('tasks: one completion entry per occurrence', () {
    late _Phone phone;

    setUp(() => phone = _Phone(firestore, uid: 'uid-kareem'));
    tearDown(() => phone.close());

    test('complete, untick, complete again: one entry', () async {
      await phone.tasks.addTask(id: 't1', title: 'Feed the cat');
      for (var i = 0; i < 3; i++) {
        await phone.tasks.setCompleted('t1', true);
        await phone.tasks.setCompleted('t1', false);
      }
      await phone.tasks.setCompleted('t1', true);
      expect((await phone.entries(ActivityTypes.taskCompleted)).map((r) => r.id), [
        'task.completed:t1',
      ]);
    });

    test('each occurrence of a recurring task gets its own entry', () async {
      await phone.tasks.addTask(id: 't1', title: 'Water plants', recurrence: TaskRecurrence.daily);
      await phone.tasks.setCompleted('t1', true);
      final next = (await phone.db.select(phone.db.tasks).get()).firstWhere((t) => t.id != 't1');
      await phone.tasks.setCompleted(next.id, true);
      // Re-ticking the first occurrence adds nothing.
      await phone.tasks.setCompleted('t1', false);
      await phone.tasks.setCompleted('t1', true);

      final ids = (await phone.entries(ActivityTypes.taskCompleted)).map((r) => r.id).toSet();
      expect(ids, {'task.completed:t1', 'task.completed:${next.id}'});
    });

    test('offline: retries upload the one entry once', () async {
      await phone.startSync();
      await phone.tasks.addTask(id: 't1', title: 'Feed the cat');
      await _settle();
      phone.activityAdapter.offline = true;
      await phone.tasks.setCompleted('t1', true);
      await phone.tasks.setCompleted('t1', false);
      await phone.tasks.setCompleted('t1', true);
      await _settle();
      await phone.reconnect(); // still offline
      phone.activityAdapter.offline = false;
      await phone.reconnect();
      await phone.reconnect();

      expect((await cloud(ActivityTypes.taskCompleted)).map((d) => d.id), ['task.completed:t1']);
      expect(await phone.db.select(phone.db.syncOutbox).get(), isEmpty);
    });
  });

  group('two phones', () {
    late _Phone kareem;
    late _Phone mariam;

    setUp(() async {
      kareem = _Phone(firestore, uid: 'uid-kareem');
      mariam = _Phone(firestore, uid: 'uid-mariam');
      await kareem.startSync();
      await mariam.startSync();
      await kareem.tasks.addTask(id: 't1', title: 'Feed the cat');
      await _settle();
      expect(await mariam.tasks.getById('t1'), isNotNull); // synced over
    });
    tearDown(() async {
      await kareem.close();
      await mariam.close();
    });

    test('both complete the same task: one cloud entry, adopted by the later phone', () async {
      // Mariam completes it offline; Kareem completes it and syncs first.
      mariam.activityAdapter.offline = true;
      await mariam.tasks.setCompleted('t1', true);
      await kareem.tasks.setCompleted('t1', true);
      await _settle();

      mariam.activityAdapter.offline = false;
      await mariam.reconnect();

      final docs = await cloud(ActivityTypes.taskCompleted);
      expect(docs.map((d) => d.id), ['task.completed:t1']);
      expect(docs.single.data()['actorUid'], 'uid-kareem');
      // Mariam's phone now holds the stored entry, with nothing left queued.
      final local = (await mariam.entries(ActivityTypes.taskCompleted)).single;
      expect(local.actorUid, 'uid-kareem');
      expect(local.occurredAt, isNotNull);
      expect(await mariam.db.select(mariam.db.syncOutbox).get(), isEmpty);
    });

    test('both upload at the same moment: the refused one adopts, not fails', () async {
      // Mariam's upload lands just after Kareem's — the rules refuse it.
      mariam.activityAdapter.loseRaceTo = (id) => firestore
          .doc('families/$_familyId/activities/$id')
          .set({
            'type': ActivityTypes.taskCompleted,
            'actorKind': 'adult',
            'actorUid': 'uid-kareem',
            'entityType': 'task',
            'entityId': 't1',
            'metadata': {'title': 'Feed the cat'},
            'schemaVersion': 1,
            'createdAt': Timestamp.now(),
            'occurredAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
      await mariam.tasks.setCompleted('t1', true);
      await _settle();

      final queued = await mariam.db.select(mariam.db.syncOutbox).get();
      expect(queued.where((o) => o.status == SyncOutboxStatus.failed), isEmpty);
      expect(queued, isEmpty);
      final local = (await mariam.entries(ActivityTypes.taskCompleted)).single;
      expect(local.actorUid, 'uid-kareem');
      expect((await cloud(ActivityTypes.taskCompleted)), hasLength(1));
    });
  });
}

FirebaseException _error(String code) => FirebaseException(plugin: 'cloud_firestore', code: code);

class _FlakyActivityAdapter extends ActivitySyncAdapter {
  _FlakyActivityAdapter(super.db);

  bool offline = false;

  /// Simulates another phone's upload of the same entry landing first,
  /// then this upload being refused by the rules (as it would be in
  /// production: the entry already exists and may not change).
  Future<void> Function(String id)? loseRaceTo;

  @override
  Map<String, dynamic> toFirestoreFields(FamilyActivity row) {
    if (offline) throw _error('unavailable');
    final race = loseRaceTo;
    if (race != null) {
      loseRaceTo = null;
      // The other phone's write starts first (the fake applies it right
      // away); this one is then refused.
      throw _RaceLost(race(row.id));
    }
    return super.toFirestoreFields(row);
  }
}

/// Thrown by the fake as a permission-denied after the competing write.
class _RaceLost implements FirebaseException {
  _RaceLost(this.landed);
  final Future<void> landed;

  @override
  String get code => 'permission-denied';
  @override
  String? get message => 'race lost';
  @override
  String get plugin => 'cloud_firestore';
  @override
  StackTrace? get stackTrace => null;
}
