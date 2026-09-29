import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/sync_outbox_table.dart';
import 'package:org_family/data/repositories/family_profile_repository.dart';
import 'package:org_family/data/sync/adapters/family_member_sync_adapter.dart';
import 'package:org_family/data/sync/adapters/family_profile_sync_adapter.dart';
import 'package:org_family/data/sync/sync_engine.dart';

/// Lets the microtask queue (and any real [Duration]-based delays inside
/// fake_cloud_firestore's stream plumbing) drain before asserting on
/// [SyncEngine] state that a detached, unawaited chain (`start()`,
/// `enqueueUpsert`'s post-write kick) is still working through.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

Future<AppDatabase> _memberRow(AppDatabase db, {
  required String id,
  required String name,
  required DateTime updatedAt,
}) async {
  await db.into(db.familyMembers).insert(
        FamilyMembersCompanion.insert(
          id: id,
          name: name,
          colorValue: 0xFF0000,
          updatedAt: Value(updatedAt),
        ),
      );
  return db;
}

Map<String, dynamic> _remoteMemberFields({
  required String name,
  required DateTime updatedAt,
}) {
  return {
    'name': name,
    'avatarEmoji': '👨',
    'colorValue': 0,
    'role': 'adult',
    'birthday': null,
    'grade': null,
    'school': null,
    'notes': null,
    'linkedUid': null,
    'createdAt': Timestamp.fromDate(updatedAt),
    'deletedAt': null,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}

void main() {
  group('SyncEngine._mergeIncoming / _hasPendingLocalWrite', () {
    late AppDatabase db;
    late FakeFirebaseFirestore firestore;
    late SyncEngine engine;
    const familyId = 'fam-1';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      firestore = FakeFirebaseFirestore();
      engine = SyncEngine(db, firestore, [FamilyMemberSyncAdapter(db)]);
      // Pre-mark the one-time migration pass complete so these tests
      // exercise steady-state pull behavior, not the initial reconciliation
      // pass (covered separately below).
      await db.into(db.familyProfile).insertOnConflictUpdate(
            FamilyProfileCompanion.insert(
              id: const Value(1),
              initialCloudMigrationCompletedAt: Value(DateTime(2024)),
            ),
          );
    });

    tearDown(() => db.close());

    // Regression for the bug where a permanently-failed local edit wasn't
    // recognized as "pending" — see _hasPendingLocalWrite's doc comment.
    // Before the fix, an outbox row stuck at status=failed was invisible
    // to the pending-write check, so an incoming remote snapshot would
    // freely overwrite the local edit it represents, silently losing it
    // before the user ever got a chance to hit "Retry".
    test('a failed (unretried) local write is not clobbered by an incoming remote update',
        () async {
      final localEditedAt = DateTime(2025, 1, 1);
      await _memberRow(db, id: 'm1', name: 'Local Edit', updatedAt: localEditedAt);
      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              familyId: familyId,
              entityType: SyncEntityType.familyMember,
              entityId: 'm1',
              operation: SyncOperation.upsert,
              status: const Value(SyncOutboxStatus.failed),
            ),
          );

      engine.start(familyId);
      await _settle();

      // A remote change — newer than the local edit — arrives, e.g. from
      // another device, exactly the scenario that used to win.
      await firestore.collection('families/$familyId/members').doc('m1').set(
            _remoteMemberFields(
              name: 'Remote Edit',
              updatedAt: localEditedAt.add(const Duration(days: 1)),
            ),
          );
      await _settle();

      final local =
          await (db.select(db.familyMembers)..where((m) => m.id.equals('m1'))).getSingle();
      expect(local.name, 'Local Edit',
          reason: 'the failed-but-unresolved local edit must survive until the user retries it');
    });

    // Once there's no failed row left for the entity (the normal case —
    // nothing pending at all), an incoming newer remote change must still
    // apply — the fix must not make the engine permanently deaf to an
    // entity that once had a failure.
    test('an incoming remote update still applies once there is no pending local write',
        () async {
      final localEditedAt = DateTime(2025, 1, 1);
      await _memberRow(db, id: 'm2', name: 'Local', updatedAt: localEditedAt);

      engine.start(familyId);
      await _settle();

      await firestore.collection('families/$familyId/members').doc('m2').set(
            _remoteMemberFields(
              name: 'Remote',
              updatedAt: localEditedAt.add(const Duration(days: 1)),
            ),
          );
      await _settle();

      final local =
          await (db.select(db.familyMembers)..where((m) => m.id.equals('m2'))).getSingle();
      expect(local.name, 'Remote');
    });
  });

  group('SyncEngine initial reconciliation is family-scoped', () {
    // Deterministic, not timing-dependent: start() is synchronous (it sets
    // _activeFamilyId and fires the async work off unawaited) and Dart
    // guarantees at least one microtask hop at every `await`, so calling
    // start('family-A') then start('family-B') back to back — with no
    // await in between, exactly like a rapid re-entrant call would — is
    // guaranteed to flip _activeFamilyId to 'family-B' before family-A's
    // reconciliation resumes past its own first await. This reproduces the
    // preemption every run, not just occasionally.
    test('a family switch mid-reconciliation aborts the preempted family cleanly', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final firestore = FakeFirebaseFirestore();
      final engine = SyncEngine(db, firestore, [FamilyMemberSyncAdapter(db)]);
      addTearDown(db.close);

      await _memberRow(db, id: 'm1', name: 'Alex', updatedAt: DateTime(2025));

      engine.start('family-A');
      engine.start('family-B'); // preempts A before its reconciliation can run

      await _settle();

      final aDocs = await firestore.collection('families/family-A/members').get();
      expect(aDocs.docs, isEmpty,
          reason: "family-A's reconciliation must have aborted before pushing anything");

      final bDocs = await firestore.collection('families/family-B/members').get();
      expect(bDocs.docs, hasLength(1),
          reason: 'family-B is the one actually active, and should reconcile normally');

      expect(engine.activeFamilyId, 'family-B');
    });
  });

  group('SyncEngine live listener isolates per-document failures', () {
    test('a malformed sibling document does not block a well-formed one in the same collection',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final firestore = FakeFirebaseFirestore();
      final engine = SyncEngine(db, firestore, [FamilyMemberSyncAdapter(db)]);
      addTearDown(db.close);
      await db.into(db.familyProfile).insertOnConflictUpdate(
            FamilyProfileCompanion.insert(
              id: const Value(1),
              initialCloudMigrationCompletedAt: Value(DateTime(2024)),
            ),
          );
      const familyId = 'fam-2';

      engine.start(familyId);
      await _settle();

      // Malformed: FamilyMemberSyncAdapter.applyRemoteUpsert reads
      // colorValue as a non-nullable int — a missing field throws a
      // CastError while decoding this one document.
      await firestore.collection('families/$familyId/members').doc('bad').set({
        'name': 'Malformed',
        'role': 'adult',
        'createdAt': Timestamp.fromDate(DateTime(2025)),
        'updatedAt': Timestamp.fromDate(DateTime(2025)),
      });
      // A well-formed sibling, written right after — before the fix, one
      // throwing document could abort the whole docChanges loop for every
      // change delivered in the same snapshot batch.
      await firestore.collection('families/$familyId/members').doc('good').set(
            _remoteMemberFields(name: 'Good Sibling', updatedAt: DateTime(2025)),
          );
      await _settle();

      final good =
          await (db.select(db.familyMembers)..where((m) => m.id.equals('good'))).getSingleOrNull();
      expect(good, isNotNull,
          reason: 'the well-formed sibling must still be applied despite the malformed document');
      expect(good!.name, 'Good Sibling');
    });
  });

  group('SyncEngine.drainNow is reentrant-safe', () {
    // Kept as a standing safety-net for drainNow's documented contract, not
    // as proof of the underlying race: verified by temporarily reverting
    // the reentrancy guard that this test's group name refers to and
    // rerunning in isolation — it passed either way. FakeFirebaseFirestore
    // plus NativeDatabase.memory()'s in-process, effectively serialized
    // execution closes the interleaving window the real bug depended on
    // (two overlapping drains both reading the same "due" rows before
    // either's push removes them), the same way the recordLink race above
    // doesn't reproduce here either. The bug and the fix are still real —
    // this just isn't the harness that can catch a regression in it.
    test('overlapping calls do not lose or duplicate a push, and leave the outbox empty',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final firestore = FakeFirebaseFirestore();
      final engine = SyncEngine(db, firestore, [FamilyMemberSyncAdapter(db)]);
      addTearDown(db.close);
      await db.into(db.familyProfile).insertOnConflictUpdate(
            FamilyProfileCompanion.insert(
              id: const Value(1),
              initialCloudMigrationCompletedAt: Value(DateTime(2024)),
            ),
          );
      const familyId = 'fam-3';
      engine.start(familyId);
      await _settle();

      await _memberRow(db, id: 'm1', name: 'Alex', updatedAt: DateTime(2025));
      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              familyId: familyId,
              entityType: SyncEntityType.familyMember,
              entityId: 'm1',
              operation: SyncOperation.upsert,
            ),
          );

      // Two overlapping triggers, e.g. a post-write kick racing a
      // reconnect nudge — must not crash, lose the row, or leave it
      // half-processed.
      await Future.wait([engine.drainNow(), engine.drainNow()]);
      await _settle();

      final remaining = await (db.select(db.syncOutbox)
            ..where((o) => o.familyId.equals(familyId)))
          .get();
      expect(remaining, isEmpty, reason: 'the row must end up pushed and removed exactly once');

      final doc = await firestore.collection('families/$familyId/members').doc('m1').get();
      expect(doc.data()!['name'], 'Alex');
    });
  });

  group('FamilyProfileRepository.recordJoin', () {
    // Regression: recordJoin used to stamp the local FamilyProfile row's
    // updatedAt with DateTime.now() — always after the real family doc's
    // own updatedAt, set once back when the Owner created it. SyncEngine's
    // "apply only if remote is newer" check then never applied the real
    // ownerUid, so a joiner's local ownerUid stayed null forever. Fixed by
    // stamping an epoch sentinel instead, so any real remote data is
    // always considered newer.
    test("a joiner's local ownerUid is pulled down from the real, older family doc",
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final firestore = FakeFirebaseFirestore();
      final engine = SyncEngine(db, firestore, [FamilyProfileSyncAdapter(db)]);
      addTearDown(db.close);
      const familyId = 'fam-join';

      // The family doc, as it already exists in Firestore — created by the
      // real Owner well before this device ever joins.
      await firestore.collection('families').doc(familyId).set({
        'ownerUid': 'owner-uid',
        'memberUids': ['owner-uid'],
        'updatedAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
      });

      final repo = FamilyProfileRepository(db, engine);
      await repo.recordJoin(familyId: familyId, uid: 'joiner-uid');
      await _settle();

      final profile = await repo.watchProfile().first;
      expect(profile, isNotNull);
      expect(profile!.ownerUid, 'owner-uid',
          reason: "the real owner's uid must sync down despite being 'older' than the join");
    });
  });
}
