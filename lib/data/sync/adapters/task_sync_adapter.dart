import 'package:drift/drift.dart';

import '../../local/database.dart';
import '../../local/tables/sync_outbox_table.dart';
import '../../local/tables/tasks_table.dart';
import '../sync_adapter.dart';
import '../sync_firestore_x.dart';

/// Mirrors [Tasks] to `families/{familyId}/tasks/{taskId}` — every field.
class TaskSyncAdapter implements SyncAdapter<Task> {
  TaskSyncAdapter(this._db);

  final AppDatabase _db;

  @override
  SyncEntityType get entityType => SyncEntityType.task;

  @override
  String collectionPath(String familyId) => 'families/$familyId/tasks';

  @override
  bool get isSingleton => false;

  @override
  DateTime updatedAtOf(Task row) => row.updatedAt;

  @override
  DateTime? deletedAtOf(Task row) => row.deletedAt;

  @override
  Map<String, dynamic> toFirestoreFields(Task row) {
    return {
      'title': row.title,
      'description': row.description,
      'dueDate': row.dueDate,
      'dueTimeMinutes': row.dueTimeMinutes,
      'priority': row.priority.name,
      'category': row.category.name,
      'assigneeId': row.assigneeId,
      'createdByMemberId': row.createdByMemberId,
      'isCompleted': row.isCompleted,
      'completedAt': row.completedAt,
      'completedByMemberId': row.completedByMemberId,
      'recurrence': row.recurrence.name,
      'reminderType': row.reminderType.name,
      'reminderOffsetMinutes': row.reminderOffsetMinutes,
      'reminderAt': row.reminderAt,
      'createdAt': row.createdAt,
      'deletedAt': row.deletedAt,
    };
  }

  @override
  Future<Task?> getLocalById(String id) {
    // Deliberately unfiltered by deletedAt — see FamilyMemberSyncAdapter's
    // doc comment on getLocalById for why.
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<List<String>> allLocalIds(String familyId) async {
    final rows = await _db.select(_db.tasks).get();
    return rows.map((r) => r.id).toList();
  }

  @override
  Future<void> applyRemoteUpsert(String id, Map<String, dynamic> fields, DateTime updatedAt) {
    return _db.into(_db.tasks).insertOnConflictUpdate(
          TasksCompanion.insert(
            id: id,
            title: fields['title'] as String,
            description: Value(fields['description'] as String?),
            dueDate: Value(toDateOrNull(fields['dueDate'])),
            dueTimeMinutes: Value(fields['dueTimeMinutes'] as int?),
            priority: Value(TaskPriority.values.byName(fields['priority'] as String)),
            category: Value(TaskCategory.values.byName(fields['category'] as String)),
            assigneeId: Value(fields['assigneeId'] as String?),
            createdByMemberId: Value(fields['createdByMemberId'] as String?),
            isCompleted: Value(fields['isCompleted'] as bool? ?? false),
            completedAt: Value(toDateOrNull(fields['completedAt'])),
            completedByMemberId: Value(fields['completedByMemberId'] as String?),
            recurrence: Value(TaskRecurrence.values.byName(fields['recurrence'] as String)),
            reminderType: Value(TaskReminderType.values.byName(fields['reminderType'] as String)),
            reminderOffsetMinutes: Value(fields['reminderOffsetMinutes'] as int?),
            reminderAt: Value(toDateOrNull(fields['reminderAt'])),
            createdAt: Value(toDateOrNull(fields['createdAt']) ?? DateTime.now()),
            updatedAt: Value(updatedAt),
            deletedAt: Value(toDateOrNull(fields['deletedAt'])),
          ),
        );
  }
}
