import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) {
      await ensureUserProfile(cred.user!);
    }
    return cred;
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'photoUrl': null,
        'provider': 'password',
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Immediately send verification email
      await user.sendEmailVerification();
    }
    return cred;
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google sign-in was canceled by the user.',
      );
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential cred = await _auth.signInWithCredential(credential);
    final User? user = cred.user;
    if (user != null) {
      final docRef = _firestore.collection('users').doc(user.uid);
      final snap = await docRef.get();

      if (!snap.exists) {
        await docRef.set({
          'uid': user.uid,
          'name': user.displayName ?? 'Google User',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'provider': 'google',
          'emailVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'photoUrl': user.photoURL,
          'provider': 'google',
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      await ensureUserProfile(user);
    }
  }

  Future<void> reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No authenticated user found for re-authentication.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  Future<void> ensureUserProfile(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snap = await docRef.get();
    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');

    if (!snap.exists) {
      await docRef.set({
        'uid': user.uid,
        'name': user.displayName ?? 'Anonymous User',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'provider': isGoogle ? 'google' : 'password',
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = snap.data();
      if (data == null) return;

      final updates = <String, dynamic>{};
      if (!data.containsKey('photoUrl') && user.photoURL != null) {
        updates['photoUrl'] = user.photoURL;
      }
      if (!data.containsKey('provider')) {
        updates['provider'] = isGoogle ? 'google' : 'password';
      }
      if (data['emailVerified'] != user.emailVerified) {
        updates['emailVerified'] = user.emailVerified;
      }
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await docRef.update(updates);
      }
    }
  }

  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    return snap.data();
  }

  Future<void> updateUserProfileName(String uid, String newName) async {
    await _firestore.collection('users').doc(uid).update({
      'name': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      await currentUser.updateDisplayName(newName);
    }
  }
}
