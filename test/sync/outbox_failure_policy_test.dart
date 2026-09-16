import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/data/sync/outbox_failure_policy.dart';

FirebaseException _withCode(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

void main() {
  group('classifyOutboxFailure', () {
    for (final code in [
      'unavailable',
      'deadline-exceeded',
      'resource-exhausted',
      'aborted',
      'internal',
      'cancelled',
    ]) {
      test('$code is transient', () {
        expect(classifyOutboxFailure(_withCode(code)), FailureKind.transient);
      });
    }

    for (final code in [
      'permission-denied',
      'invalid-argument',
      'not-found',
      'already-exists',
      'unauthenticated',
      'failed-precondition',
    ]) {
      test('$code is permanent', () {
        expect(classifyOutboxFailure(_withCode(code)), FailureKind.permanent);
      });
    }

    test('an unrecognized Firestore error code is unknown', () {
      expect(classifyOutboxFailure(_withCode('some-future-code')), FailureKind.unknown);
    });

    test('a non-Firestore error is unknown', () {
      expect(classifyOutboxFailure(StateError('boom')), FailureKind.unknown);
    });
  });

  group('backoffForAttempt', () {
    test('escalates strictly with attempt count, ignoring jitter', () {
      DateTime baseline(int attempt) =>
          DateTime(2026).add(backoffForAttempt(attempt, random: _zeroRandom));
      var previous = baseline(0);
      for (var attempt = 1; attempt < 8; attempt++) {
        final next = baseline(attempt);
        expect(next.isAfter(previous) || next.isAtSameMomentAs(previous), isTrue,
            reason: 'attempt $attempt should not back off less than attempt ${attempt - 1}');
        previous = next;
      }
    });

    test('caps at one hour once attempts exceed the step table', () {
      final at7 = backoffForAttempt(7, random: _zeroRandom);
      final at100 = backoffForAttempt(100, random: _zeroRandom);
      expect(at7, const Duration(seconds: 3600));
      expect(at100, at7);
    });

    test('jitter adds at most one second', () {
      final withJitter = backoffForAttempt(0, random: _maxRandom);
      expect(withJitter.inMilliseconds, greaterThanOrEqualTo(5000));
      expect(withJitter.inMilliseconds, lessThan(6000));
    });
  });
}

/// A [Random] stand-in that always returns 0, for deterministic assertions
/// on the non-jitter part of [backoffForAttempt].
final _zeroRandom = _FixedRandom(0);

/// One that returns the maximum value `nextInt(1000)` can produce.
final _maxRandom = _FixedRandom(999);

class _FixedRandom implements Random {
  const _FixedRandom(this._value);
  final int _value;
  @override
  int nextInt(int max) => _value;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}
