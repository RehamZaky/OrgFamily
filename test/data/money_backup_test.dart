import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' show Blob, Timestamp;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/backup/money_backup_codec.dart';
import 'package:org_family/data/backup/money_backup_providers.dart';
import 'package:org_family/data/backup/money_backup_repository.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/budget_table.dart';

const _familyId = 'fam-1';
const _uid = 'owner-uid';

Future<void> _addTransaction(AppDatabase db, String id, int cents, {String note = ''}) {
  return db.into(db.budgetTransactions).insert(
        BudgetTransactionsCompanion.insert(
          id: id,
          amountCents: cents,
          title: 'Groceries $id',
          note: Value(note),
          date: DateTime(2026, 10, 1),
          type: const Value(TransactionType.expense),
        ),
      );
}

Future<void> _seedMoney(AppDatabase db) async {
  await _addTransaction(db, 't1', 12500);
  await _addTransaction(db, 't2', 4000);
  await db.into(db.budgetCategoryLimits).insert(BudgetCategoryLimitsCompanion.insert(
        id: 'l1',
        category: TransactionCategory.values.first,
        limitCents: 50000,
      ));
  await db.into(db.budgetSettings).insert(BudgetSettingsCompanion.insert(
        id: 'default',
        totalLimitCents: const Value(300000),
      ));
  await db.into(db.savingsGoals).insert(SavingsGoalsCompanion.insert(
        id: 'g1',
        name: 'Summer trip',
        targetCents: 1000000,
        savedCents: const Value(250000),
      ));
}

Future<Map<String, int>> _counts(AppDatabase db) async => {
      'transactions': (await db.select(db.budgetTransactions).get()).length,
      'categoryLimits': (await db.select(db.budgetCategoryLimits).get()).length,
      'settings': (await db.select(db.budgetSettings).get()).length,
      'savingsGoals': (await db.select(db.savingsGoals).get()).length,
    };

void main() {
  late AppDatabase db;
  late MoneyBackupCodec codec;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    codec = MoneyBackupCodec(db);
    await _seedMoney(db);
  });

  tearDown(() => db.close());

  group('codec', () {
    test('capture → compress → encrypt → decrypt → restore is lossless', () async {
      final key = await MoneyBackupCodec.newKey();
      final original = await codec.capture(familyId: _familyId, uid: _uid);
      final blob = await codec.encrypt(codec.encode(original), key);

      await db.delete(db.budgetTransactions).go();
      await _addTransaction(db, 'stray', 1);

      final restored = codec.decode(await codec.decrypt(blob, key), expectedFamilyId: _familyId);
      await codec.replaceLocal(restored);

      expect(await _counts(db),
          {'transactions': 2, 'categoryLimits': 1, 'settings': 1, 'savingsGoals': 1});
      final tx = await (db.select(db.budgetTransactions)..where((t) => t.id.equals('t1'))).getSingle();
      expect((tx.amountCents, tx.type, tx.date), (12500, TransactionType.expense, DateTime(2026, 10, 1)));
      final goal = await db.select(db.savingsGoals).getSingle();
      expect((goal.name, goal.savedCents), ('Summer trip', 250000));
    });

    test('the wrong key, or a tampered backup, fails to decrypt', () async {
      final blob = await codec.encrypt(
          codec.encode(await codec.capture(familyId: _familyId, uid: _uid)),
          await MoneyBackupCodec.newKey());
      await expectLater(codec.decrypt(blob, await MoneyBackupCodec.newKey()),
          throwsA(isA<MoneyBackupInvalid>()));
    });

    test('a tampered backup is rejected, not restored', () async {
      final key = await MoneyBackupCodec.newKey();
      final blob = await codec.encrypt(
          codec.encode(await codec.capture(familyId: _familyId, uid: _uid)), key);
      blob[blob.length ~/ 2] ^= 0xff;
      await expectLater(codec.decrypt(blob, key), throwsA(isA<MoneyBackupInvalid>()));
    });

    test("another family's backup, or an unknown format version, is rejected", () async {
      final plain = codec.encode(await codec.capture(familyId: 'fam-other', uid: _uid));
      expect(() => codec.decode(plain, expectedFamilyId: _familyId),
          throwsA(isA<MoneyBackupInvalid>()));

      final future = jsonDecode(utf8.decode(gzip.decode(codec.encode(
          await codec.capture(familyId: _familyId, uid: _uid))))) as Map<String, dynamic>;
      future['formatVersion'] = moneyBackupFormatVersion + 1;
      expect(
        () => codec.decode(Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(future)))),
            expectedFamilyId: _familyId),
        throwsA(isA<MoneyBackupInvalid>()),
      );
    });

    test('the content hash ignores when a snapshot was taken, but not what it holds', () async {
      final a = await codec.capture(familyId: _familyId, uid: _uid);
      final b = await codec.capture(familyId: _familyId, uid: _uid);
      expect(await codec.contentHash(a), await codec.contentHash(b));
      await _addTransaction(db, 't3', 1);
      final c = await codec.capture(familyId: _familyId, uid: _uid);
      expect(await codec.contentHash(c), isNot(await codec.contentHash(a)));
    });
  });

  group('repository', () {
    late FakeFirebaseFirestore firestore;
    late MoneyBackupRepository repo;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repo = MoneyBackupRepository(firestore, codec);
    });

    Future<MoneyBackupInfo?> back(MoneyBackupKind kind) =>
        repo.backUp(familyId: _familyId, uid: _uid, kind: kind);

    test('a backup stores only metadata and encrypted chunks — never readable data', () async {
      final info = await back(MoneyBackupKind.manual);
      expect(info!.recordCounts['transactions'], 2);
      final chunk = await firestore
          .doc('families/$_familyId/moneyBackups/${info.id}/chunks/0000')
          .get();
      final bytes = (chunk.data()!['data'] as dynamic).bytes as Uint8List;
      expect(utf8.decode(bytes, allowMalformed: true).contains('Summer trip'), isFalse);
    });

    test('restore makes a safety backup first, then replaces local Money data', () async {
      final backup = (await back(MoneyBackupKind.manual))!;
      await db.delete(db.budgetTransactions).go();
      await _addTransaction(db, 'after-backup', 777);

      await repo.restore(familyId: _familyId, uid: _uid, backup: backup);

      final ids = (await db.select(db.budgetTransactions).get()).map((t) => t.id).toSet();
      expect(ids, {'t1', 't2'});
      final safety = (await repo.list(_familyId)).where((b) => b.kind == MoneyBackupKind.safety);
      expect(safety.single.recordCounts['transactions'], 1); // the pre-restore state
    });

    test('an automatic backup is skipped when nothing changed', () async {
      expect(await back(MoneyBackupKind.auto), isNotNull);
      expect(await back(MoneyBackupKind.auto), isNull);
      await _addTransaction(db, 't3', 5);
      expect(await back(MoneyBackupKind.auto), isNotNull);
    });

    test('only the newest two automatic backups are kept', () async {
      for (var i = 0; i < 4; i++) {
        await _addTransaction(db, 'x$i', i + 1);
        await back(MoneyBackupKind.auto);
      }
      final autos = (await repo.list(_familyId)).where((b) => b.kind == MoneyBackupKind.auto);
      expect(autos, hasLength(2));
      expect(autos.first.recordCounts['transactions'], 6);
    });

    test('an interrupted upload is never listed or restorable, and is cleaned up later',
      () async {
    // A manifest left "uploading" — the connection died mid-upload.
    final stale = firestore.doc('families/$_familyId/moneyBackups/stale');
    await stale.set({
      'status': 'uploading',
      'kind': 'manual',
      'clientCreatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'chunkCount': 2,
    });
    await stale.collection('chunks').doc('0000').set({'data': Blob(Uint8List(10))});

    expect(await repo.list(_familyId), isEmpty);

    await back(MoneyBackupKind.manual); // any backup prunes abandoned uploads
    expect((await stale.get()).exists, isFalse);
    expect((await stale.collection('chunks').get()).docs, isEmpty);
  });

  test('a damaged chunk fails the checksum and nothing is restored', () async {
    final info = (await back(MoneyBackupKind.manual))!;
    await firestore
        .doc('families/$_familyId/moneyBackups/${info.id}/chunks/0000')
        .set({'data': Blob(Uint8List(info.sizeBytes))});
    await db.delete(db.budgetTransactions).go();
    await _addTransaction(db, 'keep-me', 1);

    await expectLater(repo.restore(familyId: _familyId, uid: _uid, backup: info),
        throwsA(isA<MoneyBackupInvalid>()));
    final ids = (await db.select(db.budgetTransactions).get()).map((t) => t.id);
    expect(ids, ['keep-me']);
  });

  test('at most three manual backups; deleting one makes room', () async {
      for (var i = 0; i < maxManualBackups; i++) {
        await back(MoneyBackupKind.manual);
      }
      await expectLater(back(MoneyBackupKind.manual), throwsA(isA<ManualBackupLimitReached>()));
      final oldest = (await repo.list(_familyId)).last;
      await repo.delete(_familyId, oldest);
      expect(await back(MoneyBackupKind.manual), isNotNull);
    });

    test('a family that never had Money data gets no empty automatic backup', () async {
      await db.delete(db.budgetTransactions).go();
      await db.delete(db.budgetCategoryLimits).go();
      await db.delete(db.budgetSettings).go();
      await db.delete(db.savingsGoals).go();
      expect(await back(MoneyBackupKind.auto), isNull);
    });

    test('a large history is split into several chunks and restores intact', () async {
      final random = Random(1);
      String noise() => String.fromCharCodes(List.generate(400, (_) => 33 + random.nextInt(90)));
      await db.batch((b) {
        for (var i = 0; i < 2500; i++) {
          b.insert(
            db.budgetTransactions,
            BudgetTransactionsCompanion.insert(
              id: 'bulk$i',
              amountCents: i,
              title: 'Item $i',
              note: Value(noise()),
              date: DateTime(2026, 1, 1),
            ),
          );
        }
      });
      final info = (await back(MoneyBackupKind.manual))!;
      expect(info.chunkCount, greaterThan(1));

      await db.delete(db.budgetTransactions).go();
      await repo.restore(familyId: _familyId, uid: _uid, backup: info);
      expect((await db.select(db.budgetTransactions).get()).length, 2502);
    });
  });

  group('automatic schedule', () {
    test('backs up when due, then not again within the interval', () async {
      var now = DateTime(2026, 10, 6, 9);
      final repo = MoneyBackupRepository(FakeFirebaseFirestore(), codec);
      final auto = MoneyAutoBackup(repo, now: () => now);

      expect(await auto.runIfDue(familyId: _familyId, uid: _uid), isNotNull);

      await _addTransaction(db, 't3', 5);
      now = now.add(const Duration(hours: 2)); // past the throttle, inside the interval
      expect(await auto.runIfDue(familyId: _familyId, uid: _uid), isNull);
    });
  });
}
