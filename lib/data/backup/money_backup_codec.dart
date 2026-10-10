import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../local/database.dart';

/// The current Money backup format. Bump it whenever what a snapshot
/// contains changes shape, and keep [MoneyBackupCodec.decode] able to read
/// every older version — a backup made by today's app must still restore
/// into a future one.
const moneyBackupFormatVersion = 1;

/// Thrown when a backup can't be used: wrong family, a format this app
/// doesn't understand, corrupt data, or a failed decryption.
class MoneyBackupInvalid implements Exception {
  MoneyBackupInvalid(this.reason);
  final String reason;
  @override
  String toString() => 'MoneyBackupInvalid: $reason';
}

/// One consistent copy of a family's Money data — the *source* records
/// only. Totals, balances and budget progress are always recalculated from
/// these, never stored, so a restore can't bring back stale sums.
class MoneySnapshot {
  MoneySnapshot({
    required this.familyId,
    required this.createdByUid,
    required this.createdAt,
    required this.transactions,
    required this.categoryLimits,
    required this.settings,
    required this.savingsGoals,
  });

  final String familyId;
  final String createdByUid;
  final DateTime createdAt;
  final List<BudgetTransaction> transactions;
  final List<BudgetCategoryLimit> categoryLimits;
  final List<BudgetSetting> settings;
  final List<SavingsGoal> savingsGoals;

  Map<String, int> get recordCounts => {
        'transactions': transactions.length,
        'categoryLimits': categoryLimits.length,
        'settings': settings.length,
        'savingsGoals': savingsGoals.length,
      };

  Map<String, List<Map<String, dynamic>>> get _data => {
        'transactions': [for (final r in transactions) r.toJson()],
        'categoryLimits': [for (final r in categoryLimits) r.toJson()],
        'settings': [for (final r in settings) r.toJson()],
        'savingsGoals': [for (final r in savingsGoals) r.toJson()],
      };
}

/// Turns Money data into an encrypted, compressed, versioned backup and
/// back. Pure — no Firebase — so every step is unit-testable; storage is
/// `MoneyBackupRepository`'s job.
///
/// Pipeline: snapshot → JSON (with `formatVersion`) → gzip → AES-256-GCM.
/// The encrypted blob is `nonce (12 bytes) ‖ ciphertext ‖ MAC (16 bytes)`;
/// GCM's MAC means a corrupted or tampered backup fails to decrypt instead
/// of restoring garbage.
class MoneyBackupCodec {
  MoneyBackupCodec(this._db);

  final AppDatabase _db;
  static final _cipher = AesGcm.with256bits();

  /// A fresh random 256-bit key — one per family, see
  /// `MoneyBackupRepository`.
  static Future<Uint8List> newKey() async =>
      Uint8List.fromList(await (await _cipher.newSecretKey()).extractBytes());

  Future<MoneySnapshot> capture({required String familyId, required String uid}) async {
    return _db.transaction(() async {
      return MoneySnapshot(
        familyId: familyId,
        createdByUid: uid,
        createdAt: DateTime.now(),
        transactions: await _db.select(_db.budgetTransactions).get(),
        categoryLimits: await _db.select(_db.budgetCategoryLimits).get(),
        settings: await _db.select(_db.budgetSettings).get(),
        savingsGoals: await _db.select(_db.savingsGoals).get(),
      );
    });
  }

  /// Identifies the *content* (not when it was taken), so an automatic
  /// backup can be skipped when nothing changed since the last one.
  Future<String> contentHash(MoneySnapshot s) async {
    final hash = await Sha256().hash(utf8.encode(jsonEncode(s._data)));
    return base64Url.encode(hash.bytes);
  }

  Uint8List encode(MoneySnapshot s) {
    final json = jsonEncode({
      'formatVersion': moneyBackupFormatVersion,
      'familyId': s.familyId,
      'createdByUid': s.createdByUid,
      'createdAt': s.createdAt.toUtc().toIso8601String(),
      'data': s._data,
    });
    return Uint8List.fromList(gzip.encode(utf8.encode(json)));
  }

  /// Parses and validates a decrypted backup before anything is restored:
  /// a known format version, the expected family, every row well-formed,
  /// and no duplicate ids. Throws [MoneyBackupInvalid] otherwise.
  MoneySnapshot decode(Uint8List compressed, {required String expectedFamilyId}) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(gzip.decode(compressed))) as Map<String, dynamic>;
    } catch (_) {
      throw MoneyBackupInvalid('unreadable');
    }
    final version = json['formatVersion'];
    if (version is! int || version < 1 || version > moneyBackupFormatVersion) {
      throw MoneyBackupInvalid('unsupported format $version');
    }
    if (json['familyId'] != expectedFamilyId) {
      throw MoneyBackupInvalid('belongs to another family');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) throw MoneyBackupInvalid('missing data');
    List<T> rows<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final list = data[key];
      if (list is! List) throw MoneyBackupInvalid('missing $key');
      try {
        return [for (final r in list) fromJson(r as Map<String, dynamic>)];
      } catch (_) {
        throw MoneyBackupInvalid('malformed $key');
      }
    }

    final snapshot = MoneySnapshot(
      familyId: json['familyId'] as String,
      createdByUid: json['createdByUid'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime(1970),
      transactions: rows('transactions', BudgetTransaction.fromJson),
      categoryLimits: rows('categoryLimits', BudgetCategoryLimit.fromJson),
      settings: rows('settings', BudgetSetting.fromJson),
      savingsGoals: rows('savingsGoals', SavingsGoal.fromJson),
    );
    void unique(String what, Iterable<String> ids) {
      final list = ids.toList();
      if (list.toSet().length != list.length) throw MoneyBackupInvalid('duplicate $what');
    }

    unique('transactions', snapshot.transactions.map((r) => r.id));
    unique('categoryLimits', snapshot.categoryLimits.map((r) => r.id));
    unique('settings', snapshot.settings.map((r) => r.id));
    unique('savingsGoals', snapshot.savingsGoals.map((r) => r.id));
    return snapshot;
  }

  Future<Uint8List> encrypt(Uint8List plain, Uint8List key) async {
    final box = await _cipher.encrypt(plain, secretKey: SecretKey(key));
    return Uint8List.fromList(box.concatenation());
  }

  Future<Uint8List> decrypt(Uint8List blob, Uint8List key) async {
    try {
      final box = SecretBox.fromConcatenation(
        blob,
        nonceLength: _cipher.nonceLength,
        macLength: _cipher.macAlgorithm.macLength,
      );
      return Uint8List.fromList(await _cipher.decrypt(box, secretKey: SecretKey(key)));
    } catch (_) {
      throw MoneyBackupInvalid('could not decrypt');
    }
  }

  /// Replaces this device's Money data with [s] in one transaction — all
  /// or nothing, so a failure halfway can never leave a mix of old and
  /// restored records.
  Future<void> replaceLocal(MoneySnapshot s) async {
    await _db.transaction(() async {
      await _db.delete(_db.budgetTransactions).go();
      await _db.delete(_db.budgetCategoryLimits).go();
      await _db.delete(_db.budgetSettings).go();
      await _db.delete(_db.savingsGoals).go();
      await _db.batch((b) {
        b.insertAll(_db.budgetTransactions, s.transactions);
        b.insertAll(_db.budgetCategoryLimits, s.categoryLimits);
        b.insertAll(_db.budgetSettings, s.settings);
        b.insertAll(_db.savingsGoals, s.savingsGoals);
      });
    });
  }
}
