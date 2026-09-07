import 'package:drift/drift.dart';

import '../local/database.dart';

enum NoteSort { date, color }

class NoteRepository {
  NoteRepository(this._db);

  final AppDatabase _db;

  Stream<List<Note>> watchAll({NoteSort sort = NoteSort.date}) {
    return (_db.select(_db.notes)
          ..orderBy(sort == NoteSort.date
              ? [(n) => OrderingTerm.desc(n.updatedAt)]
              : [
                  (n) => OrderingTerm.asc(n.colorIndex),
                  (n) => OrderingTerm.desc(n.updatedAt),
                ]))
        .watch();
  }

  Future<void> addNote({
    required String id,
    required String body,
    int colorIndex = 0,
  }) {
    return _db.into(_db.notes).insert(
          NotesCompanion.insert(
            id: id,
            body: body,
            colorIndex: Value(colorIndex),
          ),
        );
  }

  Future<void> updateNote(Note note) {
    return _db.update(_db.notes).replace(
          note.copyWith(updatedAt: DateTime.now()),
        );
  }

  Future<void> deleteNote(String id) {
    return (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();
  }
}
