import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts a Firestore-read value that should be a date — a [Timestamp]
/// on every real read, but adapters also feed this a value straight out
/// of the map about to be *written* (see `SyncEngine._pushOne`'s
/// `applyRemoteUpsert(row.entityId, resolved ?? data, ...)` fallback),
/// where a plain [DateTime] can still be present. A plain top-level
/// function rather than an extension: extension methods don't resolve
/// through a `dynamic`-typed map value (`fields['x'].toDateOrNull()`
/// silently never calls this), so this must be called as
/// `toDateOrNull(fields['x'])`.
DateTime? toDateOrNull(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
