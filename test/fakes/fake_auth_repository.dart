import 'package:firebase_auth/firebase_auth.dart';
import 'package:org_family/data/repositories/auth_repository.dart';

/// A permanently signed-out [AuthRepository] for widget tests, which run
/// without `Firebase.initializeApp()` — the real one's `FirebaseAuth.instance`
/// throws `[core/no-app]` the moment anything watches auth state.
/// Any sign-in call fails loudly via [noSuchMethod] rather than pretending
/// to succeed.
class FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
