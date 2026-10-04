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

  /// The family [uid] belongs to, from the `users/{uid}` record
  /// `SyncEngine` keeps while that account syncs — how a member signing in
  /// on a new device finds their family without another invite. Null if
  /// the account has never synced a family. Throws if Firestore can't be
  /// reached, so a lookup failure is never mistaken for "no family".
  Future<String?> lookupFamily(String uid) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    return doc.data()?['familyId'] as String?;
  }

  /// The family's owner uid — readable only by members, so call this only
  /// for a family [lookupFamily] returned.
  Future<String?> ownerOf(String familyId) async {
    final doc = await _familyDoc(familyId).get(const GetOptions(source: Source.server));
    return doc.data()?['ownerUid'] as String?;
  }

  DocumentReference<Map<String, dynamic>> _familyDoc(String familyId) =>
      _firestore.collection('families').doc(familyId);
}
