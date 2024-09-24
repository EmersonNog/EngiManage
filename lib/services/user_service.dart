// ignore_for_file: avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  static Future<String?> getUserAccessLevel() async {
    // Supondo que o nível de acesso esteja armazenado no Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return userDoc.data()?['accessLevel'] as String?;
    }
    return null;
  }
}
