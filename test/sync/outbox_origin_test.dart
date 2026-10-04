import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/sync_outbox_table.dart';
import 'package:org_family/data/sync/adapters/family_member_sync_adapter.dart';
import 'package:org_family/data/sync/sync_engine.dart';

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

/// Changes are queued whoever makes them, but only the account syncing now
/// uploads its own automatically — anything made while not syncing, or by
/// another account, waits for a member to choose (see
/// `SyncEngine.enqueueUpsert`/`inspectReview`/`resolveReview`).
void main() {
  late AppDatabase db;
  late FakeFirebaseFirestore firestore;
  late SyncEngine engine;
  const familyId = 'fam-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    firestore = FakeFirebaseFirestore();
    engine = SyncEngine(db, firestore, [FamilyMemberSyncAdapter(db)]);
  });

  tearDown(() => db.close());

  Future<void> linkedFamily({String? id = familyId, bool migrated = true}) {
    return db.into(db.familyProfile).insertOnConflictUpdate(
          FamilyProfileCompanion.insert(
            id: const Value(1),
            familyId: Value(id),
            initialCloudMigrationCompletedAt: Value(migrated ? DateTime(2024) : null),
          ),
        );
  }

  Future<void> editMember(String id) async {
    await db.into(db.familyMembers).insertOnConflictUpdate(
          FamilyMembersCompanion.insert(
            id: id,
            name: 'Member $id',
            colorValue: 0,
            updatedAt: Value(DateTime(2025)),
          ),
        );
    await engine.enqueueUpsert(db: db, type: SyncEntityType.familyMember, entityId: id);
  }

  Future<List<SyncOutboxData>> outbox() => db.select(db.syncOutbox).get();

  Future<bool> uploaded(String id) async =>
      (await firestore.doc('families/$familyId/members/$id').get()).exists;

  test('not syncing: a change is held under whoever is signed in', () async {
    await linkedFamily();
    engine.setSignedInUid('reem');
    await editMember('m1');

    final rows = await outbox();
    expect(rows.single.status, SyncOutboxStatus.held);
    expect(rows.single.originUid, 'reem');
    expect(await uploaded('m1'), isFalse);
  });

  test('not syncing and signed out: held with no origin', () async {
    await linkedFamily();
    await editMember('m1');

    final rows = await outbox();
    expect(rows.single.status, SyncOutboxStatus.held);
    expect(rows.single.originUid, isNull);
  });

  test('never linked to the cloud: nothing is queued', () async {
    // The first link's initial reconciliation uploads every local row.
    await linkedFamily(id: null, migrated: false);
    await editMember('m1');
    expect(await outbox(), isEmpty);
  });

  test("syncing uploads only the syncing account's own changes", () async {
    await linkedFamily();
    engine.setSignedInUid('reem');
    await editMember('held-1'); // made while Reem wasn't a member

    engine.start(familyId, 'kareem');
    await _settle();
    await editMember('mine');
    await _settle();

    expect(await uploaded('mine'), isTrue);
    expect(await uploaded('held-1'), isFalse);
    expect((await outbox()).map((r) => r.entityId), ['held-1']);
  });

  test("another account's pending changes are not uploaded by whoever syncs next",
      () async {
    await linkedFamily();
    await db.into(db.familyMembers).insert(
          FamilyMembersCompanion.insert(id: 'theirs', name: 'X', colorValue: 0),
        );
    await db.into(db.syncOutbox).insert(
          SyncOutboxCompanion.insert(
            familyId: familyId,
            entityType: SyncEntityType.familyMember,
            entityId: 'theirs',
            operation: SyncOperation.upsert,
            originUid: const Value('kareem'),
          ),
        );

    engine.start(familyId, 'reem');
    await _settle();

    expect(await uploaded('theirs'), isFalse);
    expect(await outbox(), hasLength(1));
  });

  /// A cloud copy of member [id] last written at [at] (server time).
  Future<void> cloudMember(String id, {required DateTime at, String name = 'Cloud'}) {
    return firestore.doc('families/$familyId/members/$id').set({
      'name': name,
      'avatarEmoji': '👨',
      'colorValue': 0,
      'role': 'adult',
      'birthday': null,
      'grade': null,
      'school': null,
      'notes': null,
      'linkedUid': null,
      'createdAt': Timestamp.fromDate(at),
      'deletedAt': null,
      'updatedAt': Timestamp.fromDate(at),
    });
  }

  Future<String?> cloudName(String id) async =>
      (await firestore.doc('families/$familyId/members/$id').get()).data()?['name'] as String?;

  Future<String?> localName(String id) async =>
      (await (db.select(db.familyMembers)..where((m) => m.id.equals(id))).getSingleOrNull())
          ?.name;

  group('reviewing held changes against the cloud', () {
    // editMember stamps local updatedAt = 2025-01-01.
    setUp(() async {
      await linkedFamily();
      await editMember('new-here'); // no cloud copy
      await editMember('stale'); // cloud changed later
      await editMember('fresher'); // changed here after the cloud
      await cloudMember('stale', at: DateTime(2025, 6, 1));
      await cloudMember('fresher', at: DateTime(2024, 6, 1));
      engine.start(familyId, 'kareem');
      await _settle();
    });

    test('each change is classified, and only safe ones default to upload', () async {
      final items = {for (final i in await engine.inspectReview()) i.entityId: i};
      expect(items['new-here']!.state, ReviewState.newOnPhone);
      expect(items['stale']!.state, ReviewState.cloudNewer);
      expect(items['fresher']!.state, ReviewState.phoneNewer);
      expect(items['new-here']!.defaultChoice, ReviewChoice.upload);
      expect(items['fresher']!.defaultChoice, ReviewChoice.upload);
      expect(items['stale']!.defaultChoice, ReviewChoice.useCloud);
    });

    test('applying the defaults never overwrites a newer cloud version', () async {
      final items = await engine.inspectReview();
      await engine.resolveReview({for (final i in items) (i.type, i.entityId): i.defaultChoice});
      await _settle();

      expect(await cloudName('stale'), 'Cloud'); // untouched...
      expect(await localName('stale'), 'Cloud'); // ...and this phone took it
      expect(await cloudName('fresher'), 'Member fresher');
      expect(await cloudName('new-here'), 'Member new-here');
      expect(await outbox(), isEmpty);
    });

    test('applying reports progress for every decision', () async {
      final items = await engine.inspectReview();
      final progress = <(int, int)>[];
      await engine.resolveReview(
        {for (final i in items) (i.type, i.entityId): i.defaultChoice},
        onProgress: (done, total) => progress.add((done, total)),
      );
      expect(progress, [(0, 3), (1, 3), (2, 3), (3, 3)]);
      await _settle(); // let the background uploads finish before tearDown
    });

    test('the member can still choose to overwrite, or keep a change on the phone', () async {
      await engine.resolveReview({
        (SyncEntityType.familyMember, 'stale'): ReviewChoice.upload,
        (SyncEntityType.familyMember, 'fresher'): ReviewChoice.phoneOnly,
      });
      await _settle();

      expect(await cloudName('stale'), 'Member stale');
      expect(await cloudName('fresher'), 'Cloud');
      expect(await localName('fresher'), 'Member fresher');
      // Undecided entities stay awaiting review.
      expect((await outbox()).map((r) => r.entityId), ['new-here']);
    });
  });

  test('clock-skew tolerance when comparing versions', () {
    final t = DateTime(2025, 1, 1, 12);
    expect(compareForReview(localUpdatedAt: t, remoteUpdatedAt: t.add(const Duration(milliseconds: 400))),
        ReviewState.inSync);
    expect(compareForReview(localUpdatedAt: t, remoteUpdatedAt: t.add(const Duration(minutes: 1))),
        ReviewState.cloudNewer);
    expect(compareForReview(localUpdatedAt: null, remoteUpdatedAt: t), ReviewState.goneLocally);
  });

  test('discardHeld: the edits stay on this device but never upload', () async {
    await linkedFamily();
    await editMember('held-1');

    engine.start(familyId, 'reem');
    await _settle();
    await engine.discardHeld();
    await _settle();

    expect(await outbox(), isEmpty);
    expect(await uploaded('held-1'), isFalse);
    final local = await (db.select(db.familyMembers)..where((m) => m.id.equals('held-1')))
        .getSingleOrNull();
    expect(local?.name, 'Member held-1');
  });

  test('a running sync records which family the account belongs to', () async {
    await linkedFamily();
    engine.start(familyId, 'reem');
    await _settle();

    final record = await firestore.doc('users/reem').get();
    expect(record.data()?['familyId'], familyId);
  });

  test('listener reconnect backoff', () {
    expect(
      [0, 1, 2, 3, 4, 50].map((a) => listenerRetryDelay(a).inSeconds),
      [5, 15, 60, 300, 300, 300],
    );
  });
}
