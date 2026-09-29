import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/repositories/family_profile_repository.dart';
import 'package:org_family/data/sync/sync_engine.dart';

void main() {
  group('FamilyProfileRepository.recordLink', () {
    late AppDatabase db;
    late FamilyProfileRepository repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = FamilyProfileRepository(db, SyncEngine.inert(db));
    });

    tearDown(() => db.close());

    // Guards the invariant recordLink's doc comment fixes: a double-tap on
    // the calling screen's Save button firing two concurrent calls must
    // never mint two different familyIds. Note this doesn't reproduce the
    // race itself — NativeDatabase.memory()'s single in-process connection
    // happens to serialize the old read-then-decide-then-write sequence
    // tightly enough (via Dart's microtask ordering) that the two calls
    // never actually interleave in this harness, buggy or not, so this
    // passed even before the fix. It's kept as a standing invariant check
    // (and documentation of the intended behavior) rather than removed;
    // proving the interleaving itself would need an executor that can
    // inject a delay between the read and the write, which is more
    // instrumentation than this is worth on its own.
    test('two concurrent calls settle on exactly one familyId', () async {
      await Future.wait([
        repo.recordLink(uid: 'uid-1', isOwner: true),
        repo.recordLink(uid: 'uid-1', isOwner: true),
      ]);

      final profile = await repo.watchProfile().first;
      expect(profile, isNotNull);
      expect(profile!.familyId, isNotNull);

      // Re-reading (as a fresh, independent recordLink call would) must
      // see the same id that's now persisted — proving there was only ever
      // one, not a second call's mint silently winning afterward.
      await repo.recordLink(uid: 'uid-1', isOwner: true);
      final afterThirdCall = await repo.watchProfile().first;
      expect(afterThirdCall!.familyId, profile.familyId);
    });

    test('familyId is stable across repeated links, never regenerated', () async {
      await repo.recordLink(uid: 'uid-1', isOwner: true);
      final first = (await repo.watchProfile().first)!.familyId;

      await repo.recordLink(uid: 'uid-1', isOwner: true);
      final second = (await repo.watchProfile().first)!.familyId;

      expect(second, first);
    });
  });
}
