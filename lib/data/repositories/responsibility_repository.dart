import 'package:drift/drift.dart';

import '../local/database.dart';
import '../local/tables/responsibilities_table.dart';

class ResponsibilityRepository {
  ResponsibilityRepository(this._db);

  final AppDatabase _db;

  Stream<List<Responsibility>> watchForMember(String memberId) {
    return (_db.select(_db.responsibilities)
          ..where((r) => r.memberId.equals(memberId))
          ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]))
        .watch();
  }

  Future<void> addResponsibility({
    required String id,
    required String memberId,
    required String title,
    required ResponsibilityRecurrence recurrence,
    List<int>? customWeekdays,
  }) {
    return _db.into(_db.responsibilities).insert(
          ResponsibilitiesCompanion.insert(
            id: id,
            memberId: memberId,
            title: title,
            recurrence: Value(recurrence),
            customWeekdays: Value(customWeekdays?.join(',')),
          ),
        );
  }

  Future<void> setCompletedToday(String id, bool completed) {
    return (_db.update(_db.responsibilities)..where((r) => r.id.equals(id)))
        .write(ResponsibilitiesCompanion(
      lastCompletedDate: Value(completed ? DateTime.now() : null),
    ));
  }

  Future<void> deleteResponsibility(String id) {
    return (_db.delete(_db.responsibilities)..where((r) => r.id.equals(id)))
        .go();
  }
}
