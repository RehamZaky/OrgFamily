import 'package:drift/drift.dart';

import '../../local/database.dart';
import '../../local/tables/sync_outbox_table.dart';
import '../sync_adapter.dart';

/// Mirrors the singleton [FamilySettings] row to
/// `families/{familyId}/settings/{familyId}` — its own document rather than
/// fields on the family doc, which older builds overwrite with a full
/// `set()` and would wipe.
///
/// Only the Owner can write it (firestore.rules). There's no local row until
/// the Owner saves or the cloud copy arrives, so a family without the
/// document simply uses the defaults and nothing is uploaded on its behalf.
class FamilySettingsSyncAdapter implements SyncAdapter<FamilySetting> {
  FamilySettingsSyncAdapter(this._db);

  final AppDatabase _db;
  static const _rowId = 1;

  @override
  SyncEntityType get entityType => SyncEntityType.familySettings;

  @override
  String collectionPath(String familyId) => 'families/$familyId/settings';

  @override
  bool get isSingleton => true;

  @override
  DateTime updatedAtOf(FamilySetting row) => row.updatedAt;

  @override
  DateTime? deletedAtOf(FamilySetting row) => null;

  @override
  Map<String, dynamic> toFirestoreFields(FamilySetting row) => {
    'schoolWeekdays': parseWeekdays(row.schoolWeekdays),
    'weekStartDay': row.weekStartDay,
  };

  @override
  Future<FamilySetting?> getLocalById(String id) =>
      (_db.select(_db.familySettings)..where((s) => s.id.equals(_rowId))).getSingleOrNull();

  @override
  Future<List<String>> allLocalIds(String familyId) async =>
      (await getLocalById(familyId)) == null ? const [] : [familyId];

  @override
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt) {
    final days = (fields['schoolWeekdays'] as List?)?.whereType<num>().map((n) => n.toInt());
    final start = (fields['weekStartDay'] as num?)?.toInt();
    return _db
        .into(_db.familySettings)
        .insertOnConflictUpdate(
          FamilySettingsCompanion.insert(
            id: const Value(_rowId),
            schoolWeekdays: days == null ? const Value.absent() : Value(days.join(',')),
            weekStartDay: start == null ? const Value.absent() : Value(start),
            updatedAt: updatedAt,
          ),
        );
  }
}

/// `"7,1,2"` → `[7, 1, 2]`, keeping only valid, distinct weekdays.
List<int> parseWeekdays(String csv) => [
  ...<int>{
    for (final part in csv.split(','))
      ?int.tryParse(part.trim()),
  }.where((d) => d >= 1 && d <= 7)];
