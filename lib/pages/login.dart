// ignore_for_file: use_build_context_synchronously

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sobral_app/pages/forgot_pass.dart';
import 'package:sobral_app/pages/sign_up.dart';
import '../widgets/input_widget.dart';
import 'user_home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final _firebaseAuth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CarouselSlider(
                items: [
                  Image.asset("assets/logo.jpeg", width: 300),
                  Image.asset("assets/caf.png", width: 300),
                  Image.asset("assets/sobral.png", width: 280),
                ],
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bem-vindo de volta!",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
                  ),
                  Text(
                    "Preencha com seu email e senha",
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    CustomTextField(
                      hintText: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.email,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: 'Senha',
                      isPassword: true,
                      icon: Icons.lock,
                      controller: _passwordController,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ));
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: 'Esqueceu sua ',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'senha?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ));
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'Não tem uma conta? ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Crie uma!',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  login() async {
    setState(() {
      isLoading =
          true; // Ativa o indicador de loading quando o login é iniciado
    });

    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('accounts')
            .doc('approved')
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          // Conta ainda não aprovada
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sua conta ainda não foi aprovada."),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
            ),
          );
          await _firebaseAuth.signOut(); // Desloga o usuário
        } else {
          var approvedAt = userDoc['approvedAt'] as Timestamp;
          var approvedDate =
              DateFormat('dd/MM/yyyy').format(approvedAt.toDate());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Conta aprovada em $approvedDate."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const UserHome()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Usuário não encontrado. Verifique seus dados."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verifique seus dados ou seu acesso à rede."),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        isLoading =
            false; // Desativa o indicador de loading quando o login é concluído
      });
    }
  }
}
