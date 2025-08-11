import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social/features/auth/domain/entities/app_user.dart';
import 'package:social/features/auth/domain/repository/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      // Fetch user document to populate name and profile image
      final doc = await firebaseFirestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return AppUser(
          uid: userCredential.user!.uid,
          email: email,
          name: (data['name'] ?? '') as String,
          profileImageUrl: data['profileImageUrl'] as String?,
        );
      }

      return AppUser(
        uid: userCredential.user!.uid,
        email: email,
        name: userCredential.user?.displayName ?? '',
      );
    } catch (e) {
      throw Exception('Giriş başarısız oldu.$e');
    }
  }

  @override
  Future<AppUser?> registerWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      //sign up
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Build user from provided name (Firestore doc does not exist yet)
      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
      );
      //firestore kayıt
      await firebaseFirestore
          .collection("users")
          .doc(user.uid)
          .set(user.toJSON());

      //return user
      return user;
    } catch (e) {
      throw Exception('Kayıt başarısız oldu.$e');
    }
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }
    //user exist
    //fetch user  docum from fireb
    DocumentSnapshot userDoc = await firebaseFirestore
        .collection("users")
        .doc(firebaseUser.uid)
        .get();
    //exist kontrol
    if (!userDoc.exists) {
      return null;
    }

    final data = userDoc.data() as Map<String, dynamic>;
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      name: (data['name'] ?? '') as String,
      profileImageUrl: data['profileImageUrl'] as String?,
    );
  }
}
