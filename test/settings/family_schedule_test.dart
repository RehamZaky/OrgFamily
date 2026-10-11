import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/data/local/tables/sync_outbox_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/data/repositories/family_settings_repository.dart';
import 'package:org_family/data/sync/adapters/family_settings_sync_adapter.dart';
import 'package:org_family/data/sync/sync_engine.dart';
import 'package:org_family/features/calendar/screens/calendar_screen.dart';
import 'package:org_family/l10n/app_localizations.dart';

import '../fakes/fake_notification_service.dart';

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 50));

const _familyId = 'fam-1';
const _ownerUid = 'uid-kareem';
const _mondayToFriday = FamilySchedule(schoolWeekdays: {1, 2, 3, 4, 5}, weekStartDay: 1);

class _FlakySettingsAdapter extends FamilySettingsSyncAdapter {
  _FlakySettingsAdapter(super.db);

  String? failWith; // a FirebaseException code, while set

  @override
  Map<String, dynamic> toFirestoreFields(FamilySetting row) {
    final code = failWith;
    if (code != null) throw FirebaseException(plugin: 'cloud_firestore', code: code);
    return super.toFirestoreFields(row);
  }
}

/// One phone of the family, sharing the test's fake Firestore.
class _Phone {
  _Phone(FirebaseFirestore firestore, this.uid) : db = AppDatabase.forTesting(NativeDatabase.memory()) {
    adapter = _FlakySettingsAdapter(db);
    engine = SyncEngine(db, firestore, [adapter]);
    settings = FamilySettingsRepository(db, engine);
  }

  final String uid;
  final AppDatabase db;
  late final _FlakySettingsAdapter adapter;
  late final SyncEngine engine;
  late final FamilySettingsRepository settings;

  Future<void> startSync() async {
    await db
        .into(db.familyProfile)
        .insertOnConflictUpdate(
          FamilyProfileCompanion.insert(
            id: const Value(1),
            familyId: const Value(_familyId),
            ownerUid: const Value(_ownerUid),
            initialCloudMigrationCompletedAt: Value(DateTime(2024)),
          ),
        );
    engine.start(_familyId, uid);
    await _settle();
  }

  Future<FamilySchedule> schedule() => settings.watchSchedule().first;

  Future<List<SyncOutboxData>> outbox() => db.select(db.syncOutbox).get();

  Future<void> reconnect() async {
    await db.update(db.syncOutbox).write(const SyncOutboxCompanion(nextRetryAt: Value(null)));
    await engine.drainNow();
    await _settle();
  }

  Future<void> close() async {
    engine.stop();
    await db.close();
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  setUp(() => firestore = FakeFirebaseFirestore());

  DocumentReference<Map<String, dynamic>> cloudDoc() =>
      firestore.doc('families/$_familyId/settings/$_familyId');

  test('a family without the settings document uses the defaults — nothing uploaded', () async {
    final kareem = _Phone(firestore, _ownerUid);
    addTearDown(kareem.close);
    await kareem.startSync();
    expect(await kareem.schedule(), FamilySchedule.defaults);
    expect((await cloudDoc().get()).exists, isFalse);
    expect(await kareem.db.select(kareem.db.familySettings).get(), isEmpty);
    expect(await kareem.outbox(), isEmpty);
  });

  test("the Owner's offline change is kept over a cloud copy, uploaded on reconnect, "
      'and reaches the other phone', () async {
    final kareem = _Phone(firestore, _ownerUid);
    final mariam = _Phone(firestore, 'uid-mariam');
    addTearDown(kareem.close);
    addTearDown(mariam.close);
    await kareem.startSync();
    await mariam.startSync();

    kareem.adapter.failWith = 'unavailable'; // offline
    await kareem.settings.save(_mondayToFriday, signedInUid: _ownerUid);
    await _settle();
    expect(await kareem.schedule(), _mondayToFriday);
    expect(await kareem.outbox(), hasLength(1));

    // Meanwhile a different cloud copy appears (e.g. the Owner's other
    // device), newer than the local edit: it must not overwrite it.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await cloudDoc().set({
      'schoolWeekdays': [6, 7],
      'weekStartDay': 6,
      'updatedAt': Timestamp.now(), // after the local edit
    });
    await _settle();
    expect(await kareem.schedule(), _mondayToFriday);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    kareem.adapter.failWith = null; // back online
    await kareem.reconnect();
    expect((await cloudDoc().get()).data()!['schoolWeekdays'], [1, 2, 3, 4, 5]);
    expect((await cloudDoc().get()).data()!['weekStartDay'], 1);
    expect(await kareem.outbox(), isEmpty);

    // Mariam's phone picks it up and her schedule follows.
    expect(await mariam.schedule(), _mondayToFriday);
  });

  test("Kareem's offline change waits for Kareem — never uploaded or dropped under Reem", () async {
    // One shared phone.
    final phone = _Phone(firestore, _ownerUid);
    addTearDown(phone.close);
    await phone.startSync();
    phone.adapter.failWith = 'unavailable'; // Kareem is offline
    await phone.settings.save(_mondayToFriday, signedInUid: _ownerUid);
    await _settle();

    // Kareem signs out; Reem signs in; the connection comes back.
    phone.engine.stop();
    phone.engine.start(_familyId, 'uid-reem');
    await _settle();
    phone.adapter.failWith = null;
    await phone.reconnect();

    expect((await cloudDoc().get()).exists, isFalse); // not uploaded as Reem
    // Not offered for Reem to review (upload would fail for good, "keep on
    // this phone" would drop it)…
    expect(await phone.engine.inspectReview(), isEmpty);
    await phone.engine.discardHeld(); // "Keep all on this phone"
    final row = (await phone.outbox()).single; // …and still queued as Kareem's.
    expect(row.originUid, _ownerUid);
    expect(row.status, isNot(SyncOutboxStatus.failed));

    // Kareem signs back in: it uploads.
    phone.engine.stop();
    phone.engine.start(_familyId, _ownerUid);
    await _settle();
    await phone.reconnect();
    expect((await cloudDoc().get()).data()!['schoolWeekdays'], [1, 2, 3, 4, 5]);
    expect(await phone.outbox(), isEmpty);
  });

  test("an Adult can't change it — even acting as the Owner's profile", () async {
    final mariam = _Phone(firestore, 'uid-mariam');
    addTearDown(mariam.close);
    await mariam.startSync();
    // The acting profile isn't part of the check at all: only the account.
    expect(await mariam.settings.canEdit('uid-mariam'), isFalse);
    await expectLater(
      mariam.settings.save(_mondayToFriday, signedInUid: 'uid-mariam'),
      throwsA(isA<NotFamilyOwnerException>()),
    );
    expect(await mariam.schedule(), FamilySchedule.defaults);
    expect(await mariam.outbox(), isEmpty);
  });

  test('a write the rules refuse fails for good — not retried forever', () async {
    final kareem = _Phone(firestore, _ownerUid);
    addTearDown(kareem.close);
    await kareem.startSync();
    kareem.adapter.failWith = 'permission-denied';
    await kareem.settings.save(_mondayToFriday, signedInUid: _ownerUid);
    await _settle();
    final row = (await kareem.outbox()).single;
    expect(row.status, SyncOutboxStatus.failed);
    await kareem.engine.drainNow(); // automatic drains skip failed rows
    await _settle();
    expect((await kareem.outbox()).single.attemptCount, row.attemptCount);
  });

  group('week start', () {
    test('the week begins on the chosen day', () {
      final wed = DateTime(2026, 10, 14, 15); // a Wednesday
      expect(FamilySchedule.defaults.weekStart(wed), DateTime(2026, 10, 11)); // Sunday
      expect(_mondayToFriday.weekStart(wed), DateTime(2026, 10, 12)); // Monday
      const saturday = FamilySchedule(schoolWeekdays: {}, weekStartDay: 6);
      expect(saturday.weekStart(wed), DateTime(2026, 10, 10));
      expect(saturday.weekStart(DateTime(2026, 10, 10, 8)), DateTime(2026, 10, 10));
    });

    testWidgets('changing it keeps the calendar on the selected date', (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(400 * 2, 1000 * 2);
      addTearDown(tester.view.reset);
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          syncEngineProvider.overrideWithValue(SyncEngine.inert(db)),
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        ],
      );
      final today = DateTime.now();
      final other = DateTime(today.year, today.month, today.day == 15 ? 16 : 15, 10);
      await tester.runAsync(() async {
        await container
            .read(familyRepositoryProvider)
            .addMember(
              id: 'me',
              name: 'Kareem',
              avatarEmoji: '👨',
              colorValue: 0xFF7C4DFF,
              role: FamilyRole.owner,
            );
        await container
            .read(eventRepositoryProvider)
            .addEvent(id: 'e1', title: 'Swimming lesson', startAt: other);
        await container
            .read(eventRepositoryProvider)
            .addEvent(id: 'e0', title: 'Control today', startAt: DateTime(today.year, today.month, today.day, 23));
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CalendarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Events have loaded (today's shows) before picking another day.
      expect(find.text('Control today'), findsOneWidget);
      await tester.tap(find.text('${other.day}').first);
      await tester.pumpAndSettle();
      expect(find.text('Swimming lesson'), findsWidgets);

      await tester.runAsync(
        () => container.read(familySettingsRepositoryProvider).save(_mondayToFriday, signedInUid: null),
      );
      await tester.pumpAndSettle();
      // Re-laid from Monday, still on the same selected day.
      expect(find.text('Swimming lesson'), findsWidgets);

      container.dispose();
      await tester.pump(Duration.zero);
      await tester.runAsync(db.close);
    });
  });
}
