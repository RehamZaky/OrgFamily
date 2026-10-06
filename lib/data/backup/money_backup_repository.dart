import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart' show Sha256;

import 'money_backup_codec.dart';

enum MoneyBackupKind {
  /// Made automatically, at most daily and only when Money changed. Only
  /// the newest two are kept ("current" and "previous").
  auto,

  /// Made with "Back up now". Kept until deleted, up to [maxManualBackups]
  /// (with the two automatic ones, at most five per family).
  manual,

  /// Made automatically right before a restore, so restoring the wrong
  /// backup can be undone. Only the newest one is kept.
  safety,
}

const maxManualBackups = 3;
const _keepAuto = 2;
const _keepSafety = 1;

/// Comfortably under Firestore's 1 MiB document limit, leaving room for
/// document overhead.
const _chunkBytes = 600 * 1024;

/// How the bytes are encrypted, recorded per backup so a future key or
/// cipher change can still open older backups.
const moneyBackupEncryptionVersion = 1;
const _algorithm = 'AES-256-GCM';

/// A manifest still "uploading" this long after it started was abandoned
/// (connection lost mid-upload) — its chunks are cleaned up.
const _abandonedAfter = Duration(hours: 1);

String _chunkId(int i) => i.toString().padLeft(4, '0');

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// What the backup list shows — everything but the data itself.
class MoneyBackupInfo {
  MoneyBackupInfo({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.createdByUid,
    required this.recordCounts,
    required this.sizeBytes,
    required this.contentHash,
    required this.chunkCount,
    required this.checksum,
  });

  final String id;
  final MoneyBackupKind kind;
  final DateTime createdAt;
  final String createdByUid;
  final Map<String, int> recordCounts;
  final int sizeBytes;
  final String contentHash;
  final int chunkCount;

  /// SHA-256 of the encrypted bytes — checked after download, before
  /// decrypting, so a missing or damaged chunk is caught up front.
  final String checksum;

  factory MoneyBackupInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MoneyBackupInfo(
      id: doc.id,
      kind: MoneyBackupKind.values.firstWhere(
        (k) => k.name == d['kind'],
        orElse: () => MoneyBackupKind.manual,
      ),
      createdAt: (d['clientCreatedAt'] as Timestamp).toDate(),
      createdByUid: d['createdByUid'] as String? ?? '',
      recordCounts: {
        for (final e in ((d['recordCounts'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toInt(),
      },
      sizeBytes: (d['encryptedSize'] as num?)?.toInt() ?? 0,
      contentHash: d['contentHash'] as String? ?? '',
      chunkCount: (d['chunkCount'] as num?)?.toInt() ?? 0,
      checksum: d['checksum'] as String? ?? '',
    );
  }
}

class ManualBackupLimitReached implements Exception {}

/// Encrypted Money backups for a family, stored in Firestore — a disaster-
/// recovery copy, not sync: restoring replaces *this device's* Money data
/// and nothing else (see docs/roadmap.md "Money backup").
///
/// Layout, all readable and writable only by the family Owner
/// (firestore.rules):
/// - `families/{id}/moneyBackupKey/key` — the family's random AES-256 key,
///   created on first backup. Lives with the family, not the phone, so
///   the Owner can restore on any device they sign into.
/// - `families/{id}/moneyBackups/{backupId}` — the manifest: metadata
///   only, with `status` `uploading` until every chunk is written and
///   verified, then `complete`. Only complete backups are ever listed or
///   restored, so a backup interrupted mid-upload can't be restored.
/// - `families/{id}/moneyBackups/{backupId}/chunks/{0000…}` — the
///   encrypted bytes as Firestore `Bytes` (not Base64), ~600 KB each.
///
/// **Temporary V2 security trade-off — the key.** The raw key is stored in
/// Firestore, protected only by the Owner-only rule. Client-side
/// encryption therefore protects the backup bytes themselves (e.g. a
/// leaked export), but not against someone with Firebase project-owner
/// access, who could read the key too. Wrapping the key with another key
/// kept in Firestore wouldn't change that — the Owner must be able to
/// unwrap it on a brand-new phone, so the wrapping key would need to be in
/// Firestore as well. Real separation needs a secret outside Firestore: an
/// Owner passphrase or a server-side KMS (which needs the Blaze plan).
/// `encryptionVersion`/`keyVersion` are recorded so either can be adopted
/// later without breaking existing backups. See docs/roadmap.md.
///
/// Firestore rather than Cloud Storage: Cloud Storage requires the paid
/// Blaze plan, and compressed Money backups are small. The layout keeps
/// metadata separate from the bytes, so moving the bytes to Cloud Storage
/// later doesn't change the app's backup screens.
class MoneyBackupRepository {
  MoneyBackupRepository(this._firestore, this._codec);

  final FirebaseFirestore _firestore;
  final MoneyBackupCodec _codec;

  static const _server = GetOptions(source: Source.server);

  DocumentReference<Map<String, dynamic>> _keyDoc(String familyId) =>
      _firestore.doc('families/$familyId/moneyBackupKey/key');

  CollectionReference<Map<String, dynamic>> _backups(String familyId) =>
      _firestore.collection('families/$familyId/moneyBackups');

  Future<Uint8List> _key(String familyId) async {
    final doc = await _keyDoc(familyId).get(_server);
    final existing = doc.data()?['key'];
    if (existing is Blob) return existing.bytes;
    final key = await MoneyBackupCodec.newKey();
    await _keyDoc(familyId).set({
      'key': Blob(key),
      'keyVersion': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return key;
  }

  /// Complete backups, newest first. Reads the (few) manifests and sorts
  /// locally, so no composite index is needed.
  Future<List<MoneyBackupInfo>> list(String familyId) async {
    final snap = await _backups(familyId).get(_server);
    final infos = [
      for (final d in snap.docs)
        if (d.data()['status'] == 'complete') MoneyBackupInfo.fromDoc(d),
    ];
    infos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return infos;
  }

  /// Backs up this device's Money data. An [MoneyBackupKind.auto] backup is
  /// skipped (returns null) when the content is identical to the newest
  /// automatic one, or when there has never been any Money data at all —
  /// so quiet families don't keep re-uploading the same thing.
  Future<MoneyBackupInfo?> backUp({
    required String familyId,
    required String uid,
    required MoneyBackupKind kind,
  }) async {
    final existing = await list(familyId);
    if (kind == MoneyBackupKind.manual &&
        existing.where((b) => b.kind == MoneyBackupKind.manual).length >= maxManualBackups) {
      throw ManualBackupLimitReached();
    }
    final snapshot = await _codec.capture(familyId: familyId, uid: uid);
    final hash = await _codec.contentHash(snapshot);
    if (kind == MoneyBackupKind.auto) {
      final lastAuto = existing.where((b) => b.kind == MoneyBackupKind.auto).firstOrNull;
      if (lastAuto?.contentHash == hash) return null;
      if (lastAuto == null && snapshot.recordCounts.values.every((n) => n == 0)) return null;
    }
    final encrypted = await _codec.encrypt(_codec.encode(snapshot), await _key(familyId));
    final checksum = _hex((await Sha256().hash(encrypted)).bytes);

    final ref = _backups(familyId).doc();
    final chunkCount = max(1, (encrypted.length / _chunkBytes).ceil());
    final createdAt = DateTime.now();
    // 1. Manifest first, as "uploading" — never listed or restorable yet.
    await ref.set({
      'status': 'uploading',
      'kind': kind.name,
      'formatVersion': moneyBackupFormatVersion,
      'encryptionVersion': moneyBackupEncryptionVersion,
      'keyVersion': 1,
      'algorithm': _algorithm,
      'createdAt': FieldValue.serverTimestamp(),
      'clientCreatedAt': Timestamp.fromDate(createdAt),
      'createdByUid': uid,
      'recordCounts': snapshot.recordCounts,
      'encryptedSize': encrypted.length,
      'chunkCount': chunkCount,
      'contentHash': hash,
      'checksum': checksum,
    });
    // 2. The chunks, one write each (no batch-size ceiling on big backups).
    for (var i = 0; i < chunkCount; i++) {
      final end = min((i + 1) * _chunkBytes, encrypted.length);
      await ref.collection('chunks').doc(_chunkId(i)).set({
        'data': Blob(Uint8List.sublistView(encrypted, i * _chunkBytes, end)),
      });
    }
    // 3. Verify every chunk is there with the right size, then mark the
    //    backup complete — the only point it becomes restorable.
    final written = await ref.collection('chunks').get(_server);
    final writtenBytes = written.docs.fold<int>(
      0,
      (total, d) => total + ((d.data()['data'] as Blob?)?.bytes.length ?? 0),
    );
    if (written.docs.length != chunkCount || writtenBytes != encrypted.length) {
      throw StateError('backup upload incomplete');
    }
    await ref.update({'status': 'complete'});
    await _prune(familyId);
    return MoneyBackupInfo(
      id: ref.id,
      kind: kind,
      createdAt: createdAt,
      createdByUid: uid,
      recordCounts: snapshot.recordCounts,
      sizeBytes: encrypted.length,
      contentHash: hash,
      chunkCount: chunkCount,
      checksum: checksum,
    );
  }

  /// Replaces this device's Money data with [backup]. First makes a
  /// [MoneyBackupKind.safety] backup of the current data (so the wrong
  /// restore can be undone), then downloads, decrypts and validates the
  /// backup completely before touching anything local.
  Future<void> restore({
    required String familyId,
    required String uid,
    required MoneyBackupInfo backup,
  }) async {
    final key = await _key(familyId);
    final blob = BytesBuilder(copy: false);
    for (var i = 0; i < backup.chunkCount; i++) {
      final chunk = await _backups(familyId)
          .doc(backup.id)
          .collection('chunks')
          .doc(_chunkId(i))
          .get(_server);
      final data = chunk.data()?['data'];
      if (data is! Blob) throw MoneyBackupInvalid('missing part $i');
      blob.add(data.bytes);
    }
    final encrypted = blob.takeBytes();
    if (_hex((await Sha256().hash(encrypted)).bytes) != backup.checksum) {
      throw MoneyBackupInvalid('checksum mismatch');
    }
    final snapshot = _codec.decode(
      await _codec.decrypt(encrypted, key),
      expectedFamilyId: familyId,
    );
    await backUp(familyId: familyId, uid: uid, kind: MoneyBackupKind.safety);
    await _codec.replaceLocal(snapshot);
  }

  Future<void> delete(String familyId, MoneyBackupInfo backup) async {
    final ref = _backups(familyId).doc(backup.id);
    final batch = _firestore.batch();
    for (var i = 0; i < backup.chunkCount; i++) {
      batch.delete(ref.collection('chunks').doc(_chunkId(i)));
    }
    batch.delete(ref);
    await batch.commit();
  }

  /// Keeps the newest [_keepAuto] automatic and [_keepSafety] safety
  /// backups (manual ones are only ever removed by the Owner), and cleans
  /// up uploads abandoned mid-way.
  Future<void> _prune(String familyId) async {
    final manifests = await _backups(familyId).get(_server);
    final cutoff = DateTime.now().subtract(_abandonedAfter);
    for (final d in manifests.docs) {
      if (d.data()['status'] == 'complete') continue;
      final started = (d.data()['clientCreatedAt'] as Timestamp?)?.toDate();
      if (started != null && started.isAfter(cutoff)) continue;
      final chunks = await d.reference.collection('chunks').get(_server);
      for (final c in chunks.docs) {
        await c.reference.delete();
      }
      await d.reference.delete();
    }
    final all = await list(familyId);
    for (final (kind, keep) in [
      (MoneyBackupKind.auto, _keepAuto),
      (MoneyBackupKind.safety, _keepSafety),
    ]) {
      for (final old in all.where((b) => b.kind == kind).skip(keep)) {
        await delete(familyId, old);
      }
    }
  }
}
