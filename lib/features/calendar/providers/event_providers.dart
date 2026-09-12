import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../../data/providers.dart';

final allEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAll();
});

final upcomingEventsProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchUpcoming();
});

/// Member ids attached to a specific event — empty means unassigned, one
/// means single-person, two or more means shared/family.
final eventMembersProvider =
    StreamProvider.family<List<String>, String>((ref, eventId) {
  return ref.watch(eventRepositoryProvider).watchMembersForEvent(eventId);
});

/// Every event's member ids at once, keyed by event id — for filtering and
/// bucketing a whole list of events by assignee in one watch.
final allEventMembersProvider = StreamProvider<Map<String, List<String>>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAllEventMembers();
});
