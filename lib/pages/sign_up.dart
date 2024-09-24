// ignore_for_file: use_build_context_synchronously

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as Firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sobral_app/pages/login.dart';
import 'package:sobral_app/widgets/input_widget.dart';
import '../model/user.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String _selectedAccessLevel = '';

  List<String> accessLevels = [
    'MASTER',
    'GESTOR',
    'ENGENHARIA',
    'SOCIAL',
    'AMBIENTAL',
    'SEINFRA',
    'SEUMA',
    'PRODESOL',
    'PREFEITO'
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Cadastro de Usuário'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
              const SizedBox(height: 20),
              Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          hintText: "Nome",
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hintText: "E-mail",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hintText: "Senha",
                          controller: _passwordController,
                          keyboardType: TextInputType.visiblePassword,
                          icon: Icons.lock,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hintText: "Confirmar Senha",
                          controller: _confirmPasswordController,
                          keyboardType: TextInputType.visiblePassword,
                          icon: Icons.lock,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: DropdownButtonFormField(
                            value: _selectedAccessLevel.isNotEmpty
                                ? _selectedAccessLevel
                                : null,
                            onChanged: (newValue) {
                              setState(() {
                                _selectedAccessLevel = newValue.toString();
                              });
                            },
                            items: [
                              ...accessLevels.map((accessLevel) {
                                return DropdownMenuItem(
                                  value: accessLevel,
                                  child: Text(
                                    accessLevel,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                );
                              }),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Nível de Acesso',
                              labelStyle: const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    const BorderSide(color: Colors.black),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide:
                                    const BorderSide(color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                if (_passwordController.text !=
                                    _confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("As senhas não coincidem."),
                                      backgroundColor: Colors.redAccent,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (_passwordController.text.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "A senha é muito curta. Deve ter pelo menos 6 caracteres."),
                                      backgroundColor: Colors.redAccent,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                if (_nameController.text.isEmpty ||
                                    _emailController.text.isEmpty ||
                                    _passwordController.text.isEmpty ||
                                    _confirmPasswordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("Preencha todos os campos."),
                                      backgroundColor: Colors.redAccent,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                User newUser = User(
                                  name: _nameController.text,
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  accessLevel: _selectedAccessLevel,
                                );

                                await FirebaseFirestore.instance
                                    .collection('accounts')
                                    .doc('pending')
                                    .collection('users')
                                    .doc()
                                    .set(
                                  {
                                    'name': newUser.name,
                                    'email': newUser.email,
                                    'password': newUser.password,
                                    'accessLevel': newUser.accessLevel,
                                    'status': 'Pendente',
                                  },
                                );

                                await Firebase.FirebaseAuth.instance.signOut();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Cadastro realizado com sucesso. Sua conta está pendente de aprovação."),
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
                              } catch (e) {
                                if (e is Firebase.FirebaseAuthException) {
                                  if (e.code == 'invalid-email') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'O endereço de e-mail está em um formato inválido.'),
                                        backgroundColor: Colors.redAccent,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else if (e.code == 'email-already-in-use') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'O endereço de e-mail já está em uso.'),
                                        backgroundColor: Colors.redAccent,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Erro ao cadastrar usuário: $e'),
                                        backgroundColor: Colors.redAccent,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Erro ao cadastrar usuário: $e'),
                                      backgroundColor: Colors.redAccent,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Cadastrar'),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Login(),
                                ));
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: 'Já possui uma conta? ',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Entre!',
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
