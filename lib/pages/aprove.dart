// ignore_for_file: use_build_context_synchronously, use_rethrow_when_possible

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as Firebase;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sobral_app/pages/login.dart';
import 'package:sobral_app/pages/middleware.dart';

class ApprovalScreen extends StatelessWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 70, 96, 209),
        title: const Text(
          'Aprovação de Contas',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChecagemPage(),
                  ));
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('accounts')
            .doc('pending')
            .collection('users')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(
              child: Lottie.asset('assets/users.json'),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[300],
                          child: Text(
                            user['name'][0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(user['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['email'],
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('${user['accessLevel']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () async {
                                  approveUser(context, user.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("Usuário aprovado com sucesso."),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Login(),
                                    ),
                                  );
                                }),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => rejectUser(user.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void approveUser(BuildContext context, String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('accounts')
          .doc('pending')
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Usuário não encontrado."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      var userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Dados do usuário estão vazios."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (userData['status'] == 'Aprovado') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Este usuário já foi aprovado."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      String password = userData['password'];
      userData['status'] = 'Aprovado';
      userData['approvedAt'] = FieldValue.serverTimestamp();
      userData.remove('password');

      try {
        Firebase.UserCredential userCredential =
            await Firebase.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: userData['email'],
          password: password,
        );

        await FirebaseFirestore.instance
            .collection('accounts')
            .doc('approved')
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userData);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(userData);

        await FirebaseFirestore.instance
            .collection('accounts')
            .doc('pending')
            .collection('users')
            .doc(userId)
            .delete();
      } on Firebase.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("O email já está em uso por outra conta."),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          throw e;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aprovar usuário: $e'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void rejectUser(String userId) async {
    await FirebaseFirestore.instance
        .collection('accounts')
        .doc('pending')
        .collection('users')
        .doc(userId)
        .delete();
  }
}
