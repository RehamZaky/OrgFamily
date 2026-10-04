import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/repositories/family_profile_repository.dart';
import 'package:org_family/data/sync/sync_engine.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Guards the sync gate: Firestore admits only the family's owner or an
/// invite-joined uid, so sync must start for exactly those accounts — a
/// second adult who merely linked a local profile on the owner's device
/// used to start a sync whose every read and write was denied.
void main() {
  late AppDatabase db;
  late FakeFirebaseFirestore firestore;
  late FamilyProfileRepository profiles;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    firestore = FakeFirebaseFirestore();
    profiles = FamilyProfileRepository(db, SyncEngine.inert(db));
  });

  tearDown(() => db.close());

  Future<(CloudAccess, String?)> evaluate(String? signedInUid) async {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      firestoreProvider.overrideWithValue(firestore),
      authStateProvider.overrideWith(
        (ref) => Stream.value(signedInUid == null ? null : _FakeUser(signedInUid)),
      ),
    ]);
    addTearDown(container.dispose);
    container.listen(cloudAccessProvider, (_, _) {});
    await container.read(authStateProvider.future);
    await container.read(familyProfileStreamProvider.future);
    // Let the not-a-member path's remote grant check (and, if it finds a
    // grant, the markJoined write it triggers) settle.
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return (
      container.read(cloudAccessProvider),
      container.read(activeSyncFamilyIdProvider),
    );
  }

  test('signed out: no access, no sync', () async {
    await profiles.recordLink(uid: 'owner', isOwner: true);
    final (access, familyId) = await evaluate(null);
    expect(access, CloudAccess.none);
    expect(familyId, isNull);
  });

  test('the owner syncs', () async {
    await profiles.recordLink(uid: 'owner', isOwner: true);
    final (access, familyId) = await evaluate('owner');
    expect(access, CloudAccess.member);
    expect(familyId, isNotNull);
  });

  test("another account on the owner's device does not sync", () async {
    await profiles.recordLink(uid: 'owner', isOwner: true);
    // What LinkMemberScreen does for a second adult on this device: a local
    // link only, no invite grant.
    await profiles.recordLink(uid: 'second-adult', isOwner: false);
    final (access, familyId) = await evaluate('second-adult');
    expect(access, CloudAccess.notMember);
    expect(familyId, isNull);
  });

  test("an invite-joined account on the owner's device syncs", () async {
    await profiles.recordLink(uid: 'owner', isOwner: true);
    await profiles.markJoined('second-adult');
    final (access, familyId) = await evaluate('second-adult');
    expect(access, CloudAccess.member);
    expect(familyId, isNotNull);
  });

  test("a joiner on a fresh device syncs before the owner's uid arrives", () async {
    await profiles.recordJoin(familyId: 'fam-1', uid: 'joiner');
    final (access, familyId) = await evaluate('joiner');
    expect(access, CloudAccess.member);
    expect(familyId, 'fam-1');
  });

  test('a join that predates the local marker is confirmed from Firestore', () async {
    await profiles.recordLink(uid: 'owner', isOwner: true);
    final familyId = (await profiles.watchProfile().first)!.familyId!;
    await firestore
        .collection('families')
        .doc(familyId)
        .collection('joinedUids')
        .doc('second-adult')
        .set({'inviteCode': 'ABC123'});
    final (access, activeFamilyId) = await evaluate('second-adult');
    expect(access, CloudAccess.member);
    expect(activeFamilyId, familyId);
    expect((await profiles.watchProfile().first)!.joinedUid, 'second-adult');
  });

  test('an Adult who linked before the Owner waits instead of syncing', () async {
    await profiles.recordLink(uid: 'adult', isOwner: false);
    final (access, familyId) = await evaluate('adult');
    expect(access, CloudAccess.awaitingOwner);
    expect(familyId, isNull);
  });

  test('markJoined leaves updatedAt untouched for last-write-wins', () async {
    await profiles.recordLink(uid: 'owner', isOwner: true);
    final before = (await profiles.watchProfile().first)!.updatedAt;
    await profiles.markJoined('second-adult');
    final after = (await profiles.watchProfile().first)!;
    expect(after.joinedUid, 'second-adult');
    expect(after.updatedAt, before);
  });
}
