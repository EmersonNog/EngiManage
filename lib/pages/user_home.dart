// ignore_for_file: use_build_context_synchronously, avoid_print, use_key_in_widget_constructors
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sobral_app/pages/annex.dart';
import 'package:sobral_app/pages/new_work.dart';
import 'aprove.dart';
import 'home.dart';
import '../services/pdf_export.dart';

class UserHome extends StatefulWidget {
  const UserHome({Key? key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  late String _userName = '';
  late String _userAccessLevel = '';
  int _selectedIndex = 0;
  late final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        QuerySnapshot<Map<String, dynamic>> querySnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: user.email)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          Map<String, dynamic> userData = querySnapshot.docs.first.data();
          setState(() {
            _userName = userData['name'];
            _userAccessLevel = userData['accessLevel'];
          });
        } else {
          print('Usuário não encontrado');
        }
      } else {
        print('Usuário não autenticado');
      }
    } catch (error) {
      print('Erro ao buscar dados do usuário: $error');
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/checagem');
    } catch (error) {
      print('Erro ao fazer logout: $error');
    }
  }

  Future<void> _onItemTapped(int index) async {
    if (index == 2) {
      await _showObrasListForPDF();
      return;
    }

    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });
  }

  Future<void> _showObrasListForPDF() async {
    try {
      var querySnapshot =
          await FirebaseFirestore.instance.collection('work').get();
      List<QueryDocumentSnapshot> obras = querySnapshot.docs;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Selecione uma obra',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: obras.map((obra) {
                      final obraNome = obra['nome'] ?? 'Obra sem nome';
                      return Card(
                        elevation: 2.0,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 15.0),
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          title: Text(
                            obraNome,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 16.0,
                          ),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await exportToPDF([obra]);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (error) {
      _showExportErrorDialog('Erro ao buscar obras: $error');
    }
  }

  void _showExportErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erro ao exportar dados'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 70, 96, 209),
      appBar: AppBar(
        title: const Text(
          'Painel de Obras',
          style: TextStyle(color: Color.fromARGB(221, 255, 255, 255)),
        ),
        backgroundColor: const Color.fromARGB(255, 70, 96, 209),
        leading: const Icon(Icons.account_circle,
            color: Color.fromARGB(221, 255, 255, 255)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Annex(),
                  ));
            },
            icon: const Icon(Icons.attach_file_sharp,
                color: Color.fromARGB(221, 255, 255, 255)),
          ),
          if (_userAccessLevel == 'MASTER' || _userAccessLevel == 'GESTOR')
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApprovalScreen(),
                    ));
              },
              icon: const Icon(
                Icons.group_add_rounded,
                color: Colors.white,
              ),
            ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout,
                color: Color.fromARGB(221, 255, 255, 255)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Olá, ${_userName.split(" ").first}!',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.security,
                      color: Color.fromARGB(255, 255, 209, 4),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nível de Acesso: $_userAccessLevel',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color.fromARGB(255, 255, 209, 4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                children: const [
                  Home(),
                  UserFormPage(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.construction),
            label: 'Obras',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Nova obra',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_download),
            label: 'Exportar',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> exportToPDF(List<QueryDocumentSnapshot> obras) async {
    await PDFExporter.exportToPDF(obras, context);
  }
}
