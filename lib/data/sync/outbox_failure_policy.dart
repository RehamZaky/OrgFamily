import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// See `docs/architecture.md` "Firestore sync" § "Outbox failure policy".
enum FailureKind { transient, permanent, unknown }

/// How many unknown-error attempts to allow before giving up on a row —
/// past this, `SyncEngine` marks it `failed` rather than retrying forever
/// on an unclassified error. Transient errors are never limited this way.
const unknownFailureRetryLimit = 3;

/// Classifies a push failure so `SyncEngine` knows whether to keep
/// retrying with backoff, give up immediately, or fall back to a capped
/// number of attempts. Pulled out of `SyncEngine` as a pure function
/// (no Firestore *instance* needed, just the exception type) so it's
/// unit-testable without any real Firestore connection.
FailureKind classifyOutboxFailure(Object error) {
  if (error is! FirebaseException) return FailureKind.unknown;
  switch (error.code) {
    case 'unavailable':
    case 'deadline-exceeded':
    case 'resource-exhausted':
    case 'aborted':
    case 'internal':
    case 'cancelled':
      return FailureKind.transient;
    case 'permission-denied':
    case 'invalid-argument':
    case 'not-found':
    case 'already-exists':
    case 'unauthenticated':
    case 'failed-precondition':
      return FailureKind.permanent;
    default:
      return FailureKind.unknown;
  }
}

/// ~5s → 15s → 1m → 5m → 15m → 30m → capped at 1h, plus up to 1s of
/// jitter so multiple pending rows don't all retry in lockstep.
Duration backoffForAttempt(int attemptCount, {Random? random}) {
  const stepsSeconds = [5, 15, 60, 300, 900, 1800, 3600];
  final seconds = stepsSeconds[attemptCount.clamp(0, stepsSeconds.length - 1)];
  return Duration(seconds: seconds, milliseconds: (random ?? Random()).nextInt(1000));
}
