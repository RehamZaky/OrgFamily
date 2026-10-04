import 'dart:async';

import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/repositories/cloud_membership_repository.dart';
import 'package:org_family/data/repositories/family_profile_repository.dart';
import 'package:org_family/data/sync/sync_engine.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Firestore's membership answer, scripted per test — the real one is
/// exercised against the emulator by firestore_rules_test/.
class _ScriptedMembership implements CloudMembershipRepository {
  MembershipStatus status = MembershipStatus.notMember;
  int checks = 0;

  @override
  Future<MembershipStatus> verify(String familyId) async {
    checks++;
    return status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// An inert engine whose denial signal the test controls.
class _DenialEngine extends SyncEngine {
  _DenialEngine(super.db) : super.inert();

  final denials = StreamController<void>.broadcast();

  @override
  Stream<void> get accessDenied => denials.stream;
}

/// Guards the sync gate. Firestore admits only the family's owner or an
/// invite-joined uid, and Firestore — not the local `joinedUid` record —
/// is the authority: the record is a cache that lets sync start offline,
/// but a server "no" (e.g. a revoked grant) overrides it.
void main() {
  late AppDatabase db;
  late FamilyProfileRepository profiles;
  late _ScriptedMembership membership;
  late _DenialEngine engine;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    profiles = FamilyProfileRepository(db, SyncEngine.inert(db));
    membership = _ScriptedMembership();
    engine = _DenialEngine(db);
  });

  tearDown(() => db.close());

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<ProviderContainer> containerFor(String? signedInUid) async {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      syncEngineProvider.overrideWithValue(engine),
      cloudMembershipRepositoryProvider.overrideWithValue(membership),
      authStateProvider.overrideWith(
        (ref) => Stream.value(signedInUid == null ? null : _FakeUser(signedInUid)),
      ),
    ]);
    addTearDown(container.dispose);
    container.listen(cloudAccessProvider, (_, _) {});
    await container.read(authStateProvider.future);
    await container.read(familyProfileStreamProvider.future);
    await settle();
    return container;
  }

  Future<(CloudAccess, String?)> evaluate(String? signedInUid) async {
    final container = await containerFor(signedInUid);
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

  test('the owner syncs without asking Firestore', () async {
    await profiles.recordLink(uid: 'owner', isOwner: true);
    final (access, familyId) = await evaluate('owner');
    expect(access, CloudAccess.member);
    expect(familyId, isNotNull);
    expect(membership.checks, 0);
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

  test('a cached join that Firestore confirms syncs', () async {
    await profiles.recordLink(uid: 'owner', isOwner: true);
    await profiles.markJoined('second-adult');
    membership.status = MembershipStatus.member;
    final (access, familyId) = await evaluate('second-adult');
    expect(access, CloudAccess.member);
    expect(familyId, isNotNull);
  });

  test('a cached join still syncs offline, when Firestore cannot be asked', () async {
    await profiles.recordJoin(familyId: 'fam-1', uid: 'joiner');
    membership.status = MembershipStatus.unknown;
    final (access, familyId) = await evaluate('joiner');
    expect(access, CloudAccess.member);
    expect(familyId, 'fam-1');
  });

  test('a revoked grant overrides the cached join and clears it', () async {
    await profiles.recordJoin(familyId: 'fam-1', uid: 'joiner');
    membership.status = MembershipStatus.notMember;
    final (access, familyId) = await evaluate('joiner');
    expect(access, CloudAccess.notMember);
    expect(familyId, isNull);
    expect((await profiles.watchProfile().first)!.joinedUid, isNull);
  });

  test('a denial while syncing re-checks membership and stops sync if revoked', () async {
    await profiles.recordJoin(familyId: 'fam-1', uid: 'joiner');
    membership.status = MembershipStatus.member;
    final container = await containerFor('joiner');
    expect(container.read(activeSyncFamilyIdProvider), 'fam-1');

    membership.status = MembershipStatus.notMember;
    engine.denials.add(null);
    await settle();

    expect(container.read(cloudAccessProvider), CloudAccess.notMember);
    expect(container.read(activeSyncFamilyIdProvider), isNull);
    expect(membership.checks, 2);
  });

  test('membership Firestore confirms without a local record is recorded', () async {
    // A join from before the local record existed, or on another device.
    await profiles.recordLink(uid: 'owner', isOwner: true);
    membership.status = MembershipStatus.member;
    final (access, _) = await evaluate('second-adult');
    expect(access, CloudAccess.member);
    expect((await profiles.watchProfile().first)!.joinedUid, 'second-adult');
  });

  test('an Adult who linked before the Owner waits instead of syncing', () async {
    await profiles.recordLink(uid: 'adult', isOwner: false);
    final (access, familyId) = await evaluate('adult');
    expect(access, CloudAccess.awaitingOwner);
    expect(familyId, isNull);
  });

  test("restoring on a new device records the account's role", () async {
    await profiles.recordRestore(familyId: 'fam-1', uid: 'joiner', isOwner: false);
    var profile = (await profiles.watchProfile().first)!;
    expect((profile.familyId, profile.ownerUid, profile.joinedUid), ('fam-1', null, 'joiner'));

    await profiles.recordRestore(familyId: 'fam-2', uid: 'owner', isOwner: true);
    profile = (await profiles.watchProfile().first)!;
    expect((profile.familyId, profile.ownerUid, profile.joinedUid), ('fam-2', 'owner', null));
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
