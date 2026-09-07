import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/note_repository.dart';

final noteSortProvider = StateProvider<NoteSort>((ref) => NoteSort.date);

final notesProvider = StreamProvider<List<Note>>((ref) {
  final sort = ref.watch(noteSortProvider);
  return ref.watch(noteRepositoryProvider).watchAll(sort: sort);
});
