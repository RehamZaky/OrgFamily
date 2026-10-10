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
    this.inviterName,
  });

  final String code;
  final String familyId;
  final DateTime expiresAt;
  final String? usedByUid;

  /// The inviting adult's own member name, for the joiner's "Join
  /// `<name>'s family?`" confirmation — null on invites created before this
  /// field existed (or with no linked member to name), where the screen
  /// falls back to a generic "Join this family?".
  final String? inviterName;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedByUid != null;
  bool get isUsable => !isExpired && !isUsed;

  /// Whole days left, rounded up — "Expires in 7 days" right after
  /// creation, "1 day" for anything under a day but not yet expired.
  int get daysLeft {
    final hours = expiresAt.difference(DateTime.now()).inMinutes / 60;
    return max(1, (hours / 24).ceil());
  }
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

  /// Must stay in step with the `expiresAt` cap in `firestore.rules`
  /// (this plus a one-hour clock-skew allowance) — a longer value here
  /// would have every invite rejected at creation.
  static const _validity = Duration(days: 7);
  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I
  static const _codeLength = 8;
  static const _maxInviterNameLength = 80; // firestore.rules' own bound

  /// Reduces whatever the joiner typed or pasted to the bare stored code.
  /// A pasted share message (see the invite screen's Share button) is
  /// recognised by its `XXXX-XXXX` token, so the words around it don't
  /// get glued onto the code; otherwise case, the [formatCode] dash,
  /// spaces and punctuation are all just stripped. Also keeps a stray `/`
  /// from ever reaching `doc()`, which would treat it as a path separator.
  static String normalizeCode(String input) {
    final upper = input.toUpperCase();
    final dashed = RegExp(
      r'(?<![A-Z0-9])[A-Z0-9]{4}-[A-Z0-9]{4}(?![A-Z0-9])',
    ).firstMatch(upper);
    return (dashed?.group(0) ?? upper).replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// `7K9XQPRT` → `7K9X-QPRT`, purely for reading aloud or retyping —
  /// [normalizeCode] strips the dash back out on the way in.
  static String formatCode(String code) => code.length == _codeLength
      ? '${code.substring(0, _codeLength ~/ 2)}-${code.substring(_codeLength ~/ 2)}'
      : code;

  String _generateCode() {
    final rand = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _codeAlphabet[rand.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// Creates a new invite for [familyId] and returns it — share the code with the joining adult out of band (text
  /// message, etc). The UI shows the returned invite's own `expiresAt`
  /// rather than a hardcoded "7 days", so what the inviter is told always matches the
  /// invite actually written. [inviterName] is shown to the joiner before
  /// they commit (see [FamilyInvite.inviterName]). No collision check on
  /// the code itself: 8 characters from a 32-symbol alphabet is ~1.1
  /// trillion combinations, so an overwrite of another live invite is not
  /// a realistic concern.
  Future<FamilyInvite> createInvite({
    required String familyId,
    required String creatorUid,
    String? inviterName,
  }) async {
    final code = _generateCode();
    // Computed client-side rather than via serverTimestamp() + a
    // follow-up read, unlike the sync engine's updatedAt — the rules
    // allow an hour of device clock skew past the 7 days, and this way
    // the code is usable (and its exact expiry known) the instant this
    // write resolves.
    final expiresAt = DateTime.now().add(_validity);
    final trimmed = inviterName?.trim() ?? '';
    final name = trimmed.length > _maxInviterNameLength
        ? trimmed.substring(0, _maxInviterNameLength)
        : trimmed;
    await _firestore.collection('invites').doc(code).set({
      'familyId': familyId,
      'createdByUid': creatorUid,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'usedByUid': null,
      'usedAt': null,
      if (name.isNotEmpty) 'inviterName': name,
    });
    return FamilyInvite(
      code: code,
      familyId: familyId,
      expiresAt: expiresAt,
      usedByUid: null,
      inviterName: name.isEmpty ? null : name,
    );
  }

  /// Looks up [code] without claiming it — lets the join screen show a
  /// clear "expired"/"already used" message before committing to joining.
  /// Returns null if the code doesn't exist at all.
  Future<FamilyInvite?> lookupInvite(String code) async {
    final normalized = normalizeCode(code);
    if (normalized.isEmpty) return null;
    final snap = await _firestore.collection('invites').doc(normalized).get();
    final data = snap.data();
    if (data == null) return null;
    return _fromData(normalized, data);
  }

  /// Every invite [creatorUid] has made, newest expiry first — backs
  /// Settings' "Manage invites". Must filter on `createdByUid` exactly
  /// this way: `firestore.rules` only allows a list query it can prove
  /// returns the caller's own invites.
  Future<List<FamilyInvite>> listInvitesCreatedBy(String creatorUid) async {
    final snap = await _firestore
        .collection('invites')
        .where('createdByUid', isEqualTo: creatorUid)
        .get();
    return snap.docs.map((d) => _fromData(d.id, d.data())).toList()
      ..sort((a, b) => b.expiresAt.compareTo(a.expiresAt));
  }

  /// Revokes an invite early — only its creator may (see
  /// `firestore.rules`). The UI only offers this for unused invites:
  /// deleting a claimed one would strand a joiner whose second claim
  /// write ([claimInvite]) hasn't landed yet.
  Future<void> revokeInvite(String code) =>
      _firestore.collection('invites').doc(code).delete();

  FamilyInvite _fromData(String code, Map<String, dynamic> data) =>
      FamilyInvite(
        code: code,
        familyId: data['familyId'] as String,
        expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        usedByUid: data['usedByUid'] as String?,
        inviterName: data['inviterName'] as String?,
      );

  /// Claims [invite] for [uid]: marks it used, then grants standing access
  /// via a `joinedUids/{uid}` doc. Two sequential writes, not one atomic
  /// transaction — see the class doc comment and docs/architecture.md for
  /// why a failure between them (a claimed-but-ungranted invite) is an
  /// acceptable degraded case rather than a security gap. Throws
  /// [FirebaseException] (permission-denied) if someone else claimed the
  /// same code in the meantime.
  ///
  /// Safe to call again for an invite [uid] itself already claimed — the
  /// joiner backing out of profile setup and tapping Join again, or a
  /// retry after the second write failed: the claim is skipped, and the
  /// grant only written if it isn't there yet (`joinedUids` docs are
  /// create-only, so re-setting an existing one would be denied).
  Future<void> claimInvite(FamilyInvite invite, String uid) async {
    final joinedRef = _firestore
        .collection('families')
        .doc(invite.familyId)
        .collection('joinedUids')
        .doc(uid);
    if (invite.usedByUid == uid) {
      if (await _grantExists(joinedRef)) return;
    } else {
      await _firestore.collection('invites').doc(invite.code).update({
        'usedByUid': uid,
        'usedAt': FieldValue.serverTimestamp(),
      });
    }
    await joinedRef.set({
      'inviteCode': invite.code,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Until the grant exists the caller isn't a family member, so
  /// `firestore.rules` denies reading it at all — permission-denied here
  /// means "not granted yet", not a real failure.
  Future<bool> _grantExists(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      return (await ref.get()).exists;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
  }
}
