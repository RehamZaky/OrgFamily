import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps [FirebaseAuth] the same way every other repository in this app
/// wraps its Drift table (`FamilyRepository(this._db)`, etc.) — a plain
/// class, constructor-injected dependency, no interface.
///
/// This identifies *who's signed in*; it says nothing about which local
/// [FamilyMember] they are — that link lives in `FamilyMember.linkedUid`
/// (see `family_repository.dart` and docs/architecture.md's "Family
/// identity and authentication").
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  bool _googleSignInInitialized = false;

  // google_sign_in v7's GoogleSignIn.instance.initialize() needs the
  // project's *web* OAuth client (google-services.json's client_type: 3,
  // not the Android client_type: 1 entry used for firebase_options.dart's
  // androidClientId) as the idToken's audience — without it,
  // GoogleSignInAuthentication.idToken comes back null on Android and
  // GoogleAuthProvider.credential has nothing to authenticate with.
  static const _googleServerClientId =
      '482713768862-jo8rcvko0hkkgfu8q0oeesbc26v0lmat.apps.googleusercontent.com';

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _googleServerClientId);
    _googleSignInInitialized = true;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignInInitialized) await GoogleSignIn.instance.signOut();
  }

  // Not wired into any UI yet — the repository is shaped to leave room for
  // it so an adult signed in with email doesn't accidentally end up with
  // two separate accounts if they later try Google Sign-In (or vice
  // versa), rather than assuming email/Google are always independent.
  Future<UserCredential> linkGoogleCredential() async {
    await _ensureGoogleSignInInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user to link a credential to.');
    return user.linkWithCredential(credential);
  }

  Future<UserCredential> linkEmailCredential({
    required String email,
    required String password,
  }) {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user to link a credential to.');
    final credential = EmailAuthProvider.credential(email: email, password: password);
    return user.linkWithCredential(credential);
  }
}
