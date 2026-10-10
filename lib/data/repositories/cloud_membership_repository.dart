import 'package:cloud_firestore/cloud_firestore.dart';

/// What Firestore says about an account's membership in a family.
enum MembershipStatus {
  member,
  notMember,

  /// Couldn't ask (offline, or some other transient failure) — callers
  /// keep whatever they last knew.
  unknown,
}

/// Server-side answers about cloud family membership — the authority the
/// local `FamilyProfile.ownerUid`/`joinedUid` records only cache. See
/// docs/architecture.md "Family invitations".
class CloudMembershipRepository {
  CloudMembershipRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Whether the signed-in account belongs to [familyId] right now. The
  /// family doc is readable exactly when the caller is its owner or holds
  /// a `joinedUids/{uid}` grant (firestore.rules), so one server read
  /// answers it — including after a grant has been revoked, which a cached
  /// local record alone would never notice.
  Future<MembershipStatus> verify(String familyId) async {
    try {
      await _familyDoc(familyId).get(const GetOptions(source: Source.server));
      return MembershipStatus.member;
    } on FirebaseException catch (e) {
      return e.code == 'permission-denied'
          ? MembershipStatus.notMember
          : MembershipStatus.unknown;
    } catch (_) {
      return MembershipStatus.unknown;
    }
  }

  /// The family [uid] currently belongs to, and its owner — how a member
  /// signing in on a new device finds their family without another invite.
  /// Starts from the `users/{uid}` record `SyncEngine` keeps while that
  /// account syncs, then confirms membership by reading the family itself.
  ///
  /// Null if the account has no family. That includes a *stale* record: a
  /// revoked member's record still names the family (revoking doesn't
  /// touch it, and only its own account may), but reading the family is
  /// denied — so the record is deleted and the account is treated as new,
  /// rather than left stuck retrying a restore that can never succeed.
  /// Throws on anything else (e.g. offline), so a lookup failure is never
  /// mistaken for "no family".
  Future<({String familyId, String? ownerUid})?> findFamily(String uid) async {
    final record = _firestore.collection('users').doc(uid);
    final familyId =
        (await record.get(const GetOptions(source: Source.server))).data()?['familyId']
            as String?;
    if (familyId == null) return null;
    try {
      final family = await _familyDoc(familyId).get(const GetOptions(source: Source.server));
      return (familyId: familyId, ownerUid: family.data()?['ownerUid'] as String?);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      try {
        await record.delete();
      } catch (_) {
        // Best-effort: it's only a pointer, and the next lookup ends here
        // again anyway.
      }
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>> _familyDoc(String familyId) =>
      _firestore.collection('families').doc(familyId);
}
