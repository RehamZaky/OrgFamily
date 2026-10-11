import 'dart:convert';

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
import 'package:org_family/data/repositories/event_repository.dart';
import 'package:org_family/data/repositories/responsibility_repository.dart';
import 'package:org_family/data/repositories/shopping_repository.dart';
import 'package:org_family/data/repositories/task_repository.dart';
import 'package:org_family/data/sync/adapters/activity_sync_adapter.dart';
import 'package:org_family/data/sync/adapters/event_sync_adapter.dart';
import 'package:org_family/data/sync/adapters/shopping_item_sync_adapter.dart';
import 'package:org_family/data/sync/adapters/responsibility_sync_adapter.dart';
import 'package:org_family/data/sync/adapters/task_sync_adapter.dart';
import 'package:org_family/data/sync/sync_engine.dart';

import '../fakes/fake_notification_service.dart';

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

/// The V2.1 family activity log: what gets recorded, that it commits with
/// the change it describes, and how it syncs.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<List<FamilyActivity>> entries() =>
      (db.select(db.familyActivities)..orderBy([(a) => OrderingTerm.asc(a.createdAt)])).get();

  group('recording', () {
    late ActivityLog log;
    late TaskRepository tasks;

    setUp(() {
      final sync = SyncEngine.inert(db);
      log = ActivityLog(sync)..setActor(uid: 'uid-kareem', memberId: 'm-kareem');
      tasks = TaskRepository(db, FakeNotificationService(), sync, activity: log);
    });

    test("an adult linked to another account isn't vouched for: not known", () async {
      await db.into(db.familyMembers).insert(
            FamilyMembersCompanion.insert(
              id: 'm-reem',
              name: 'Reem',
              colorValue: 0,
              linkedUid: const Value('uid-reem'),
            ),
          );
      log.setActor(uid: 'uid-kareem', memberId: 'm-reem'); // Reem's profile picked
      await tasks.addTask(id: 't1', title: 'Feed the cat');
      final entry = (await entries()).single;
      expect(entry.actorUid, 'uid-kareem');
      expect(entry.actorMemberId, isNull);
    });

    test('a task created and completed is recorded with who did it', () async {
      await tasks.addTask(id: 't1', title: 'Feed the cat', assigneeId: 'm-mariam');
      log.setActor(uid: 'uid-kareem', memberId: 'm-mariam');
      await tasks.setCompleted('t1', true, actingMemberId: 'm-mariam');

      final rows = await entries();
      expect(rows.map((r) => r.type), [ActivityTypes.taskCreated, ActivityTypes.taskCompleted]);
      expect(rows.map((r) => r.actorMemberId), ['m-kareem', 'm-mariam']);
      expect(rows.every((r) => r.actorUid == 'uid-kareem'), isTrue);
      expect(rows.every((r) => r.entityType == SyncEntityType.task.name), isTrue);
      expect(jsonDecode(rows.last.metadata), {'title': 'Feed the cat', 'assigneeId': 'm-mariam'});
    });

    test('completing twice, or un-completing, records nothing more', () async {
      await tasks.addTask(id: 't1', title: 'Feed the cat');
      await tasks.setCompleted('t1', true);
      await tasks.setCompleted('t1', true);
      await tasks.setCompleted('t1', false);
      expect((await entries()).map((r) => r.type), [
        ActivityTypes.taskCreated,
        ActivityTypes.taskCompleted,
      ]);
    });

    test("a recurring task's next occurrence is not a new family action", () async {
      await tasks.addTask(id: 't1', title: 'Water plants', recurrence: TaskRecurrence.daily);
      await tasks.setCompleted('t1', true);
      expect(await db.select(db.tasks).get(), hasLength(2));
      expect((await entries()).map((r) => r.type), [
        ActivityTypes.taskCreated,
        ActivityTypes.taskCompleted,
      ]);
    });

    test('reassigning records task.assigned; other edits record nothing', () async {
      await tasks.addTask(id: 't1', title: 'Feed the cat', assigneeId: 'm-mariam');
      final task = (await tasks.getById('t1'))!;
      await tasks.updateTask(task.copyWith(title: 'Feed the cats'));
      await tasks.updateTask(task.copyWith(assigneeId: const Value('m-omar')));
      final rows = await entries();
      expect(rows.map((r) => r.type), [ActivityTypes.taskCreated, ActivityTypes.taskAssigned]);
      expect(jsonDecode(rows.last.metadata)['assigneeId'], 'm-omar');
    });

    test('shopping: added, bought once, removed — with the names at the time', () async {
      final shopping = ShoppingRepository(db, SyncEngine.inert(db), activity: log);
      await db
          .into(db.shoppingLists)
          .insert(
            ShoppingListsCompanion.insert(
              id: 'l1',
              name: 'Grocery',
              updatedAt: Value(DateTime(2026)),
            ),
          );
      await shopping.addItem(id: 'i1', listId: 'l1', name: 'Milk');
      await shopping.setPurchased('i1', true);
      await shopping.setPurchased('i1', true);
      await shopping.deleteItem('i1');
      final rows = await entries();
      expect(rows.map((r) => r.type), [
        ActivityTypes.shoppingItemAdded,
        ActivityTypes.shoppingItemPurchased,
        ActivityTypes.shoppingItemRemoved,
      ]);
      expect(jsonDecode(rows.first.metadata), {
        'name': 'Milk',
        'listId': 'l1',
        'listName': 'Grocery',
      });
    });

    test('a responsibility ticked done is recorded once a day', () async {
      final chores = ResponsibilityRepository(db, SyncEngine.inert(db), activity: log);
      await chores.addResponsibility(
        id: 'r1',
        memberId: 'm-mariam',
        title: 'Make the bed',
        recurrence: ResponsibilityRecurrence.daily,
      );
      await chores.setCompletedToday('r1', true);
      await chores.setCompletedToday('r1', true);
      expect((await entries()).map((r) => r.type), [ActivityTypes.responsibilityCompleted]);
    });

    test('the entry commits with its change: a failed change leaves no entry', () async {
      await tasks.addTask(id: 't1', title: 'Feed the cat');
      await expectLater(tasks.addTask(id: 't1', title: 'Duplicate id'), throwsA(anything));
      expect(await entries(), hasLength(1));
    });
  });

  group('sync', () {
    const familyId = 'fam-1';
    late FakeFirebaseFirestore firestore;
    late SyncEngine engine;
    late ActivityLog log;
    late TaskRepository tasks;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      engine = SyncEngine(db, firestore, [TaskSyncAdapter(db), ActivitySyncAdapter(db)]);
      log = ActivityLog(engine)..setActor(uid: 'uid-kareem', memberId: 'm-kareem');
      tasks = TaskRepository(db, FakeNotificationService(), engine, activity: log);
      await db
          .into(db.familyProfile)
          .insertOnConflictUpdate(
            FamilyProfileCompanion.insert(
              id: const Value(1),
              familyId: const Value(familyId),
              initialCloudMigrationCompletedAt: Value(DateTime(2024)),
            ),
          );
    });

    Future<Map<String, dynamic>?> cloudEntry(String id) async =>
        (await firestore.doc('families/$familyId/activities/$id').get()).data();

    test('an entry uploads with a map of metadata and gets the server time back', () async {
      engine.start(familyId, 'uid-kareem');
      await _settle();
      await tasks.addTask(id: 't1', title: 'Feed the cat');
      await _settle();

      final local = (await entries()).single;
      final cloud = (await cloudEntry(local.id))!;
      expect(cloud['type'], ActivityTypes.taskCreated);
      expect(cloud['actorUid'], 'uid-kareem');
      expect(cloud['metadata'], {'title': 'Feed the cat', 'assigneeId': null});
      expect(cloud['occurredAt'], isA<Timestamp>());
      // Drift stores whole seconds.
      final serverTime = (cloud['occurredAt'] as Timestamp).toDate();
      expect(local.occurredAt!.difference(serverTime).inSeconds, 0);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    });

    test('only the recent window is pulled from the cloud', () async {
      Future<void> remote(String id, DateTime at) =>
          firestore.doc('families/$familyId/activities/$id').set({
            'type': ActivityTypes.taskCompleted,
            'actorKind': 'adult',
            'entityType': 'task',
            'entityId': 't',
            'metadata': {'title': id},
            'schemaVersion': 1,
            'createdAt': Timestamp.fromDate(at),
            'occurredAt': Timestamp.fromDate(at),
            'updatedAt': Timestamp.fromDate(at),
          });
      final now = DateTime.now();
      await remote('recent', now.subtract(const Duration(days: 2)));
      await remote('old', now.subtract(const Duration(days: 60)));

      engine.start(familyId, 'uid-kareem');
      await _settle();

      expect((await entries()).map((r) => r.id), ['recent']);
    });

    test("an unknown (newer app's) entry type syncs in without failing", () async {
      final at = DateTime.now();
      await firestore.doc('families/$familyId/activities/v3').set({
        'type': 'task.submitted_for_approval',
        'actorKind': 'child',
        'actorDeviceId': 'device-1',
        'entityType': 'task',
        'entityId': 't',
        'state': 'pending',
        'metadata': {'title': 'Homework', 'photo': true},
        'schemaVersion': 2,
        'createdAt': Timestamp.fromDate(at),
        'occurredAt': Timestamp.fromDate(at),
        'updatedAt': Timestamp.fromDate(at),
      });
      engine.start(familyId, 'uid-kareem');
      await _settle();
      final row = (await entries()).single;
      expect(row.actorKind, 'child');
      expect(row.state, 'pending');
      expect(row.schemaVersion, 2);
    });

    group('held for review', () {
      setUp(() async {
        // Made while signed in as an account the family hadn't admitted.
        engine.setSignedInUid('uid-other');
        log.setActor(uid: 'uid-other', memberId: 'm-mariam');
        await tasks.addTask(id: 't1', title: 'Feed the cat');
        engine.start(familyId, 'uid-kareem');
        await _settle();
      });

      test('the entry is not listed separately — it follows its task', () async {
        final items = await engine.inspectReview();
        expect(items.map((i) => (i.type, i.entityId)), [(SyncEntityType.task, 't1')]);
      });

      test("uploading the task uploads its entry, credited to the uploader's account", () async {
        await engine.resolveReview({(SyncEntityType.task, 't1'): ReviewChoice.upload});
        await _settle();
        final entry = (await entries()).single;
        final cloud = (await cloudEntry(entry.id))!;
        expect(cloud['actorUid'], 'uid-kareem');
        expect(cloud['actorMemberId'], 'm-mariam');
        expect(await db.select(db.syncOutbox).get(), isEmpty);
      });

      test("uploading fixes up an entry the rules would refuse", () async {
        // Signed out, on behalf of an adult linked to another account.
        await db.into(db.familyMembers).insert(
              FamilyMembersCompanion.insert(
                id: 'm-reem',
                name: 'Reem',
                colorValue: 0,
                linkedUid: const Value('uid-reem'),
              ),
            );
        engine.stop();
        engine.setSignedInUid(null);
        log.setActor(uid: null, memberId: 'm-reem');
        await tasks.addTask(id: 't2', title: 'Water plants');
        engine.start(familyId, 'uid-kareem');
        await _settle();

        await engine.resolveReview({(SyncEntityType.task, 't2'): ReviewChoice.upload});
        await _settle();
        final entry = (await entries()).firstWhere((e) => e.entityId == 't2');
        final cloud = (await cloudEntry(entry.id))!;
        expect(cloud['actorUid'], isNull); // made signed out: stays "no account"
        expect(cloud['actorMemberId'], isNull); // Reem's account didn't make it
      });

      test("using the cloud's version drops only the held entries, not mine", () async {
        // Synced as Kareem now: complete the same task — my own entry.
        log.setActor(uid: 'uid-kareem', memberId: null);
        await tasks.setCompleted('t1', true);
        await _settle();
        await firestore.doc('families/$familyId/tasks/t1').update({
          'updatedAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 1))),
        });

        await engine.resolveReview({(SyncEntityType.task, 't1'): ReviewChoice.useCloud});
        await _settle();
        await engine.drainNow();
        await _settle();
        final types = (await entries()).map((e) => e.type);
        expect(types, [ActivityTypes.taskCompleted]); // the held task.created is gone
        final mine = (await entries()).single;
        expect(await cloudEntry(mine.id), isNotNull);
      });

      test('keeping the task on the phone keeps its entry local too', () async {
        await engine.resolveReview({(SyncEntityType.task, 't1'): ReviewChoice.phoneOnly});
        await _settle();
        final entry = (await entries()).single;
        expect(await cloudEntry(entry.id), isNull);
        expect(await db.select(db.syncOutbox).get(), isEmpty);
      });
    });

    group('offline and partial uploads', () {
      late _FlakyTaskAdapter taskAdapter;
      late _FlakyActivityAdapter activityAdapter;

      setUp(() {
        taskAdapter = _FlakyTaskAdapter(db);
        activityAdapter = _FlakyActivityAdapter(db);
        engine = SyncEngine(db, firestore, [taskAdapter, activityAdapter]);
        log = ActivityLog(engine)..setActor(uid: 'uid-kareem', memberId: null);
        tasks = TaskRepository(db, FakeNotificationService(), engine, activity: log);
      });

      Future<int> cloudEntries() async =>
          (await firestore.collection('families/$familyId/activities').get()).docs.length;

      /// "Reconnect": every queued row is due now, and the queue drains.
      Future<void> reconnect() async {
        await db.update(db.syncOutbox).write(const SyncOutboxCompanion(nextRetryAt: Value(null)));
        await engine.drainNow();
        await _settle();
      }

      test('completed offline: the entry waits for its task, then both upload once', () async {
        engine.start(familyId, 'uid-kareem');
        await _settle();
        await tasks.addTask(id: 't1', title: 'Feed the cat');
        await _settle();
        expect(await cloudEntries(), 1); // task.created

        taskAdapter.offline = true;
        await tasks.setCompleted('t1', true);
        await _settle();
        // The task couldn't upload, so its entry wasn't even attempted.
        final queued = await db.select(db.syncOutbox).get();
        expect(queued.map((r) => r.entityType),
            [SyncEntityType.task, SyncEntityType.activity]);
        expect(queued.last.attemptCount, 0);
        expect(await cloudEntries(), 1);

        taskAdapter.offline = false;
        await reconnect();
        await reconnect(); // a second pass must not duplicate anything
        expect(await cloudEntries(), 2);
        expect((await firestore.doc('families/$familyId/tasks/t1').get()).data()!['isCompleted'],
            isTrue);
        expect(await db.select(db.syncOutbox).get(), isEmpty);
      });

      test("a retry whose first upload landed reads it back; its time never moves", () async {
        engine.start(familyId, 'uid-kareem');
        await _settle();
        await tasks.addTask(id: 't1', title: 'Feed the cat');
        await _settle();
        final entry = (await entries()).single;
        final stored = (await cloudEntry(entry.id))!['occurredAt'] as Timestamp;

        // As if the read-back after the upload had failed: no server time
        // locally, and the row still queued.
        await (db.update(db.familyActivities)..where((a) => a.id.equals(entry.id)))
            .write(const FamilyActivitiesCompanion(occurredAt: Value(null)));
        await db.into(db.syncOutbox).insert(
              SyncOutboxCompanion.insert(
                familyId: familyId,
                entityType: SyncEntityType.activity,
                entityId: entry.id,
                operation: SyncOperation.upsert,
                originUid: const Value('uid-kareem'),
              ),
            );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await reconnect();

        expect((await cloudEntry(entry.id))!['occurredAt'], stored);
        expect((await entries()).single.occurredAt, isNotNull);
        expect(await db.select(db.syncOutbox).get(), isEmpty);
      });

      test('the task uploaded but the entry did not: the same entry follows later', () async {
        engine.start(familyId, 'uid-kareem');
        await _settle();
        activityAdapter.offline = true;
        await tasks.addTask(id: 't1', title: 'Feed the cat');
        await _settle();
        expect((await firestore.doc('families/$familyId/tasks/t1').get()).exists, isTrue);
        expect(await cloudEntries(), 0);

        activityAdapter.offline = false;
        await reconnect();
        await reconnect();
        final docs = (await firestore.collection('families/$familyId/activities').get()).docs;
        expect(docs.map((d) => d.id), [(await entries()).single.id]);
      });
    });

    test('entries about deleted events and items upload after their tombstones, and the delete sticks', () async {
      engine = SyncEngine(db, firestore, [
        EventSyncAdapter(db),
        ShoppingItemSyncAdapter(db),
        ActivitySyncAdapter(db),
      ]);
      log = ActivityLog(engine)..setActor(uid: 'uid-kareem', memberId: null);
      final events = EventRepository(db, FakeNotificationService(), engine, activity: log);
      final shopping = ShoppingRepository(db, engine, activity: log);
      await db.into(db.shoppingLists).insert(
            ShoppingListsCompanion.insert(id: 'l1', name: 'Grocery', updatedAt: Value(DateTime(2026))),
          );
      engine.start(familyId, 'uid-kareem');
      await _settle();

      // Deleted right after being added — while the add's upload is still
      // in flight (regression: its read-back used to undo the delete).
      await events.addEvent(id: 'e1', title: 'Swimming', startAt: DateTime.now());
      await events.deleteEvent('e1');
      await shopping.addItem(id: 'i1', listId: 'l1', name: 'Rice');
      await shopping.deleteItem('i1');
      await _settle();

      expect((await firestore.doc('families/$familyId/events/e1').get()).data()!['deletedAt'],
          isNotNull);
      expect((await firestore.doc('families/$familyId/shoppingItems/i1').get()).data()!['deletedAt'],
          isNotNull);
      final cloudTypes = (await firestore.collection('families/$familyId/activities').get())
          .docs
          .map((d) => d.data()['type'])
          .toSet();
      expect(cloudTypes, {
        ActivityTypes.eventCreated,
        ActivityTypes.eventCancelled,
        ActivityTypes.shoppingItemAdded,
        ActivityTypes.shoppingItemRemoved,
      });
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    });

    test('a responsibility ticked done twice gives exactly one cloud entry', () async {
      engine = SyncEngine(db, firestore, [ResponsibilitySyncAdapter(db), ActivitySyncAdapter(db)]);
      log = ActivityLog(engine)..setActor(uid: 'uid-kareem', memberId: null);
      final chores = ResponsibilityRepository(db, engine, activity: log);
      engine.start(familyId, 'uid-kareem');
      await _settle();
      await chores.addResponsibility(
        id: 'r1',
        memberId: 'm-mariam',
        title: 'Make the bed',
        recurrence: ResponsibilityRecurrence.daily,
      );
      await chores.setCompletedToday('r1', true);
      await chores.setCompletedToday('r1', true);
      await _settle();
      final docs = (await firestore.collection('families/$familyId/activities').get()).docs;
      expect(docs.map((d) => d.data()['type']), [ActivityTypes.responsibilityCompleted]);
    });
  });
}

FirebaseException _offline() => FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');

class _FlakyTaskAdapter extends TaskSyncAdapter {
  _FlakyTaskAdapter(super.db);
  bool offline = false;

  @override
  Map<String, dynamic> toFirestoreFields(Task row) {
    if (offline) throw _offline();
    return super.toFirestoreFields(row);
  }
}

class _FlakyActivityAdapter extends ActivitySyncAdapter {
  _FlakyActivityAdapter(super.db);
  bool offline = false;

  @override
  Map<String, dynamic> toFirestoreFields(FamilyActivity row) {
    if (offline) throw _offline();
    return super.toFirestoreFields(row);
  }
}
