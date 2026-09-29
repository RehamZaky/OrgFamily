import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// A looked-up invite, before it's claimed — enough for the joining screen
/// to show a confirmation and decide whether the code is even usable.
class FamilyInvite {
  const FamilyInvite({
    required this.code,
    required this.familyId,
    required this.expiresAt,
    required this.usedByUid,
  });

  final String code;
  final String familyId;
  final DateTime expiresAt;
  final String? usedByUid;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedByUid != null;
  bool get isUsable => !isExpired && !isUsed;
}

/// Generates and redeems the short-lived, single-use codes that let a
/// second real adult — on their own device, with their own Firebase
/// account — join an existing family's cloud data. See
/// docs/architecture.md "Family invitations" for the full design: this
/// repository only ever touches the top-level `invites/{code}` collection
/// and a family's `joinedUids/{uid}` subcollection, never the family doc's
/// own `ownerUid`/`memberUids` (those stay create-once immutable).
///
/// Deliberately has no local/Drift side, unlike every other repository —
/// an invite is control-plane bookkeeping, not app data to mirror, so
/// there's nothing for a `SyncAdapter` to do here.
class FamilyInviteRepository {
  FamilyInviteRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _validity = Duration(days: 7);
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I
  static const _codeLength = 8;

  String _generateCode() {
    final rand = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _codeAlphabet[rand.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// Creates a new invite for [familyId] and returns its code and actual
  /// expiry — share the code with the joining adult out of band (text
  /// message, etc). Returning [expiresAt] alongside the code (rather than
  /// the caller hardcoding "7 days" from memory) is deliberate: this
  /// value must always be the single source of truth for what the UI
  /// tells the inviter, since `firestore.rules`' server-side cap on
  /// `expiresAt` (30 days, see its own comment) is intentionally looser
  /// than [_validity] — the two are allowed to drift, so nothing here may
  /// assume that "the rules permit up to 30 days" also means "invites are
  /// good for 30 days". No collision check on the code itself: 8
  /// characters from a 32-symbol alphabet is ~1.1 trillion combinations,
  /// so an overwrite of another live invite is not a realistic concern.
  Future<({String code, DateTime expiresAt})> createInvite({
    required String familyId,
    required String creatorUid,
  }) async {
    final code = _generateCode();
    // Computed client-side rather than via serverTimestamp() + a
    // follow-up read, unlike the sync engine's updatedAt — a 7-day expiry
    // window has enough slack that a few minutes of device clock skew
    // doesn't matter, and this way the code is usable (and its exact
    // expiry known) the instant this write resolves.
    final expiresAt = DateTime.now().add(_validity);
    await _firestore.collection('invites').doc(code).set({
      'familyId': familyId,
      'createdByUid': creatorUid,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'usedByUid': null,
      'usedAt': null,
    });
    return (code: code, expiresAt: expiresAt);
  }

  /// Looks up [code] without claiming it — lets the join screen show a
  /// clear "expired"/"already used" message before committing to joining.
  /// Returns null if the code doesn't exist at all.
  Future<FamilyInvite?> lookupInvite(String code) async {
    final normalized = code.trim().toUpperCase();
    final snap = await _firestore.collection('invites').doc(normalized).get();
    final data = snap.data();
    if (data == null) return null;
    return FamilyInvite(
      code: normalized,
      familyId: data['familyId'] as String,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      usedByUid: data['usedByUid'] as String?,
    );
  }

  /// Claims [invite] for [uid]: marks it used, then grants standing access
  /// via a `joinedUids/{uid}` doc. Two sequential writes, not one atomic
  /// transaction — see the class doc comment and docs/architecture.md for
  /// why a failure between them (a claimed-but-ungranted invite) is an
  /// acceptable degraded case rather than a security gap. Throws
  /// [FirebaseException] (permission-denied) if someone else claimed the
  /// same code in the meantime.
  Future<void> claimInvite(FamilyInvite invite, String uid) async {
    await _firestore.collection('invites').doc(invite.code).update({
      'usedByUid': uid,
      'usedAt': FieldValue.serverTimestamp(),
    });
    await _firestore
        .collection('families')
        .doc(invite.familyId)
        .collection('joinedUids')
        .doc(uid)
        .set({'inviteCode': invite.code, 'joinedAt': FieldValue.serverTimestamp()});
  }
}
