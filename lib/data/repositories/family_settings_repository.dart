import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../local/database.dart';
import '../local/tables/sync_outbox_table.dart';
import '../sync/adapters/family_settings_sync_adapter.dart';
import '../sync/sync_engine.dart';

/// The family's week (V2.2): which days are school days (when "school days"
/// responsibilities are due) and which day a week starts on (calendar's
/// first column, every "this week" figure). Shared by the whole family.
@immutable
class FamilySchedule {
  const FamilySchedule({required this.schoolWeekdays, required this.weekStartDay});

  /// What a family without saved settings uses: today's behaviour —
  /// school Sunday–Thursday, weeks starting Sunday.
  static const defaults = FamilySchedule(
    schoolWeekdays: {
      DateTime.sunday,
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
    },
    weekStartDay: DateTime.sunday,
  );

  factory FamilySchedule.fromRow(FamilySetting? row) => row == null
      ? defaults
      : FamilySchedule(
          schoolWeekdays: parseWeekdays(row.schoolWeekdays).toSet(),
          weekStartDay: row.weekStartDay >= 1 && row.weekStartDay <= 7
              ? row.weekStartDay
              : defaults.weekStartDay,
        );

  /// `DateTime.weekday` numbers.
  final Set<int> schoolWeekdays;
  final int weekStartDay;

  /// Midnight on the first day of the week containing [day].
  DateTime weekStart(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final back = (d.weekday - weekStartDay) % 7;
    return DateTime(d.year, d.month, d.day - back);
  }

  @override
  bool operator ==(Object other) =>
      other is FamilySchedule &&
      setEquals(other.schoolWeekdays, schoolWeekdays) &&
      other.weekStartDay == weekStartDay;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(schoolWeekdays), weekStartDay);

  @override
  String toString() => 'FamilySchedule(school: ${(schoolWeekdays.toList()..sort())}, weekStart: $weekStartDay)';
}

/// Thrown when someone other than the family's Owner account tries to
/// change the shared schedule.
class NotFamilyOwnerException implements Exception {
  @override
  String toString() => 'Only the family Owner can change the family schedule.';
}

class FamilySettingsRepository {
  FamilySettingsRepository(this._db, this._sync);

  final AppDatabase _db;
  final SyncEngine _sync;

  Stream<FamilySchedule> watchSchedule() => (_db.select(
    _db.familySettings,
  )..where((s) => s.id.equals(1))).watchSingleOrNull().map(FamilySchedule.fromRow);

  /// Whether [signedInUid] may change the schedule: the family's Owner
  /// **account** — never decided by the acting profile, which on a shared
  /// phone can be switched to the Owner's by anyone. A family that isn't in
  /// the cloud yet (no owner recorded) is all local, so anyone may.
  Future<bool> canEdit(String? signedInUid) async {
    final ownerUid = (await _profile())?.ownerUid;
    return ownerUid == null || ownerUid == signedInUid;
  }

  Future<FamilyProfileData?> _profile() =>
      (_db.select(_db.familyProfile)..where((p) => p.id.equals(1))).getSingleOrNull();

  Future<void> save(FamilySchedule schedule, {required String? signedInUid}) async {
    if (!await canEdit(signedInUid)) throw NotFamilyOwnerException();
    final familyId = (await _profile())?.familyId;
    final days = schedule.schoolWeekdays.where((d) => d >= 1 && d <= 7).toList()..sort();
    await _db.transaction(() async {
      await _db
          .into(_db.familySettings)
          .insertOnConflictUpdate(
            FamilySettingsCompanion.insert(
              id: const Value(1),
              schoolWeekdays: Value(days.join(',')),
              weekStartDay: Value(schedule.weekStartDay),
              updatedAt: DateTime.now(),
            ),
          );
      // A singleton is addressed by the family id (see the adapter); not
      // in the cloud yet means nothing to upload — the first link's
      // reconciliation sends the row.
      if (familyId != null) {
        await _sync.enqueueUpsert(db: _db, type: SyncEntityType.familySettings, entityId: familyId);
      }
    });
  }
}
