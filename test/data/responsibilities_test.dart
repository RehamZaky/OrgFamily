import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/core/permissions/family_permissions.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/data/local/tables/responsibilities_table.dart';
import 'package:org_family/data/repositories/responsibility_repository.dart';
import 'package:org_family/data/sync/adapters/responsibility_sync_adapter.dart';
import 'package:org_family/data/sync/adapters/task_sync_adapter.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/family/responsibility_schedule.dart';

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

Responsibility _chore(ResponsibilityRecurrence recurrence, {String? custom, DateTime? done}) =>
    Responsibility(
      id: 'r',
      memberId: 'm',
      title: 't',
      recurrence: recurrence,
      customWeekdays: custom,
      lastCompletedDate: done,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2025),
    );

// 2026-10-04 is a Sunday; 2026-10-09 a Friday; 2026-10-10 a Saturday.
final _sunday = DateTime(2026, 10, 4);
final _friday = DateTime(2026, 10, 9);
final _saturday = DateTime(2026, 10, 10);

void main() {
  group('schedule', () {
    test('school days are Sunday through Thursday', () {
      final r = _chore(ResponsibilityRecurrence.schoolDays);
      expect(isDueOn(r, _sunday), isTrue);
      expect(isDueOn(r, _friday), isFalse);
      expect(isDueOn(r, _saturday), isFalse);
      // On the weekend, it's next due Sunday.
      expect(nextDueAfter(r, _friday), DateTime(2026, 10, 11));
    });

    test('custom weekdays are due only on those days', () {
      final r = _chore(ResponsibilityRecurrence.custom, custom: '${DateTime.saturday}');
      expect(isDueOn(r, _saturday), isTrue);
      expect(isDueOn(r, _sunday), isFalse);
      expect(nextDueAfter(r, _sunday), _saturday);
    });

    test('daily is due every day', () {
      final r = _chore(ResponsibilityRecurrence.daily);
      for (var i = 0; i < 7; i++) {
        expect(isDueOn(r, _sunday.add(Duration(days: i))), isTrue);
      }
    });

    test('done today means ticked on this local date, not just ever', () {
      final r = _chore(ResponsibilityRecurrence.daily, done: _sunday.add(const Duration(hours: 9)));
      expect(isDoneOn(r, _sunday), isTrue);
      expect(isDoneOn(r, _sunday.add(const Duration(days: 1))), isFalse);
    });
  });

  group('repository', () {
    late AppDatabase db;
    late ResponsibilityRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ResponsibilityRepository(db, SyncEngine.inert(db));
      for (final (id, role) in [('kareem', FamilyRole.owner), ('omar', FamilyRole.child)]) {
        await db.into(db.familyMembers).insert(
              FamilyMembersCompanion.insert(id: id, name: id, colorValue: 0, role: Value(role)),
            );
      }
    });

    tearDown(() => db.close());

    Future<void> add(String id, String memberId, {FamilyRole as = FamilyRole.owner}) =>
        repo.addResponsibility(
          id: id,
          memberId: memberId,
          title: id,
          recurrence: ResponsibilityRecurrence.daily,
          actingRole: as,
        );

    Future<Responsibility?> row(String id) =>
        (db.select(db.responsibilities)..where((r) => r.id.equals(id))).getSingleOrNull();

    test('a Child cannot create or delete responsibilities', () async {
      await expectLater(add('x', 'omar', as: FamilyRole.child),
          throwsA(isA<FamilyPermissionException>()));
      await add('bed', 'omar');
      await expectLater(repo.deleteResponsibility('bed', actingRole: FamilyRole.child),
          throwsA(isA<FamilyPermissionException>()));
    });

    test('an Adult can create and delete responsibilities', () async {
      await add('bed', 'omar', as: FamilyRole.adult);
      await repo.deleteResponsibility('bed', actingRole: FamilyRole.adult);
      expect((await row('bed'))!.deletedAt, isNotNull);
    });

    test("a Child can tick their own responsibility, but not someone else's", () async {
      await add('bed', 'omar');
      await add('cat', 'kareem');
      await repo.setCompletedToday('bed', true,
          actingRole: FamilyRole.child, actingMemberId: 'omar');
      expect((await row('bed'))!.lastCompletedDate, isNotNull);
      await expectLater(
        repo.setCompletedToday('cat', true, actingRole: FamilyRole.child, actingMemberId: 'omar'),
        throwsA(isA<FamilyPermissionException>()),
      );
    });

    test('deleting is a soft delete that hides it from the member', () async {
      await add('bed', 'omar');
      await repo.deleteResponsibility('bed');
      expect(await repo.watchForMember('omar').first, isEmpty);
      expect((await row('bed'))!.deletedAt, isNotNull); // tombstone kept for sync
    });
  });

  group('sync', () {
    late AppDatabase db;
    late FakeFirebaseFirestore firestore;
    late SyncEngine engine;
    late ResponsibilityRepository repo;
    const familyId = 'fam-1';

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      firestore = FakeFirebaseFirestore();
      engine = SyncEngine(db, firestore, [TaskSyncAdapter(db), ResponsibilitySyncAdapter(db)]);
      repo = ResponsibilityRepository(db, engine);
    });

    tearDown(() => db.close());

    Future<void> family({String? reconciled}) =>
        db.into(db.familyProfile).insertOnConflictUpdate(
              FamilyProfileCompanion.insert(
                id: const Value(1),
                familyId: const Value(familyId),
                initialCloudMigrationCompletedAt: Value(DateTime(2024)),
                reconciledEntityTypes: Value(reconciled),
              ),
            );

    DocumentReference<Map<String, dynamic>> remote(String id) =>
        firestore.doc('families/$familyId/responsibilities/$id');

    test('creating, ticking and deleting all reach Firestore', () async {
      await family(reconciled: 'task,responsibility');
      engine.start(familyId, 'kareem');
      await _settle();

      await repo.addResponsibility(
        id: 'cat',
        memberId: 'mariam',
        title: 'Feed the cat',
        recurrence: ResponsibilityRecurrence.schoolDays,
      );
      await _settle();
      var data = (await remote('cat').get()).data()!;
      expect(data['title'], 'Feed the cat');
      expect(data['memberId'], 'mariam');
      expect(data['recurrence'], 'schoolDays');

      await repo.setCompletedToday('cat', true);
      await _settle();
      expect((await remote('cat').get()).data()!['lastCompletedDate'], isNotNull);

      await repo.deleteResponsibility('cat');
      await _settle();
      data = (await remote('cat').get()).data()!;
      expect(data['deletedAt'], isNotNull);
    });

    test("an existing family's first pass uploads its local chores once — "
        'without re-uploading a task deleted elsewhere', () async {
      // Kareem's phone before this update: tasks long reconciled, chores
      // only ever local.
      await family(reconciled: 'familyProfile,familyMember,task,event,shoppingList,shoppingItem');
      await db.into(db.responsibilities).insert(
            ResponsibilitiesCompanion.insert(
              id: 'bed',
              memberId: 'omar',
              title: 'Make bed',
              updatedAt: Value(DateTime(2025)),
            ),
          );
      // A task that's local but missing remotely — deleted elsewhere after
      // the first pass. Re-uploading it would resurrect it.
      await db.into(db.tasks).insert(
            TasksCompanion.insert(id: 'gone', title: 'Deleted elsewhere'),
          );

      engine.start(familyId, 'kareem');
      await _settle();

      expect((await remote('bed').get()).data()?['title'], 'Make bed');
      expect((await firestore.doc('families/$familyId/tasks/gone').get()).exists, isFalse);
      final profile = await db.select(db.familyProfile).getSingle();
      expect(profile.reconciledEntityTypes?.split(','), contains('responsibility'));
    });

    test('a family whose old first pass left no per-collection record still '
        'gets only the responsibilities pass', () async {
      await family(); // completed, reconciledEntityTypes null
      await db.into(db.responsibilities).insert(
            ResponsibilitiesCompanion.insert(
              id: 'bed',
              memberId: 'omar',
              title: 'Make bed',
              updatedAt: Value(DateTime(2025)),
            ),
          );
      await db.into(db.tasks).insert(TasksCompanion.insert(id: 'gone', title: 'x'));

      engine.start(familyId, 'kareem');
      await _settle();

      expect((await remote('bed').get()).exists, isTrue);
      expect((await firestore.doc('families/$familyId/tasks/gone').get()).exists, isFalse);
    });

    test("a chore assigned on another phone arrives on this one", () async {
      await family(reconciled: 'task,responsibility');
      await remote('cat').set({
        'memberId': 'mariam',
        'title': 'Feed the cat',
        'recurrence': 'daily',
        'customWeekdays': null,
        'lastCompletedDate': null,
        'createdAt': Timestamp.fromDate(DateTime(2026)),
        'deletedAt': null,
        'updatedAt': Timestamp.fromDate(DateTime(2026)),
      });
      engine.start(familyId, 'mariam-uid');
      await _settle();

      final local = await repo.watchForMember('mariam').first;
      expect(local.map((r) => r.title), ['Feed the cat']);
    });
  });
}
