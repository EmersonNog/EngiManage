// ignore_for_file: avoid_print, library_private_types_in_public_api, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../pages/home.dart';
import 'take_photo.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FotosScreen extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  const FotosScreen({Key? key, required this.obra}) : super(key: key);

  @override
  _FotosScreenState createState() => _FotosScreenState();
}

class _FotosScreenState extends State<FotosScreen> {
  late TextEditingController _albumController;
  late DateTime _selectedDate;
  String _contratoPrefix = '';
  String _selectedType = 'Ambiental';
  late String _userAccessLevel = '';

  @override
  void initState() {
    super.initState();
    _albumController = TextEditingController();
    _selectedDate = DateTime.now();
    _getContractorPrefix();
    _fetchUserData();
  }

  @override
  void dispose() {
    _albumController.dispose();
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

  Future<void> _getContractorPrefix() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('work')
          .doc(widget.obra.id)
          .get();

      if (snapshot.exists && snapshot.data()!.containsKey('num_contrato')) {
        String contrato = snapshot.data()!['num_contrato'];
        _contratoPrefix = contrato;
      }
    } catch (e) {
      print('Erro ao buscar o prefixo do contrato: $e');
    }
  }

  Future<void> _openDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _albumController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Future<bool> _verificarAlbumExistente(String nomeAlbum) async {
    DocumentSnapshot<Map<String, dynamic>> obraSnapshot =
        await FirebaseFirestore.instance
            .collection('work')
            .doc(widget.obra.id)
            .get();

    if (obraSnapshot.exists && obraSnapshot.data()!.containsKey('albums')) {
      List<dynamic>? albums = obraSnapshot['albums'];
      if (albums != null) {
        return albums.any((album) => album['name'] == nomeAlbum);
      }
    }
    return false;
  }

  Future<void> _criarAlbum() async {
    String nomeAlbum = _albumController.text.trim();
    if (nomeAlbum.isNotEmpty) {
      nomeAlbum = '$_contratoPrefix - $nomeAlbum';
      bool albumExistente = await _verificarAlbumExistente(nomeAlbum);

      if (!albumExistente) {
        await FirebaseFirestore.instance
            .collection('work')
            .doc(widget.obra.id)
            .update({
          'albums': FieldValue.arrayUnion([
            {'name': nomeAlbum, 'tipo': _selectedType}
          ])
        });
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const Home(),
        ));
      } else {
        _mostrarDialog('Erro', 'O álbum "$nomeAlbum" já existe.');
      }
      _albumController.clear();
    } else {
      _mostrarDialog('Erro', 'O nome do álbum não pode estar vazio.');
    }
  }

  Future<void> _verificarNivelAcesso(Function action) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      List<String> permittedLevels = [
        'MASTER',
        'GESTOR',
        'ENGENHARIA',
        'SOCIAL',
        'AMBIENTAL'
      ];

      if (!permittedLevels.contains(_userAccessLevel)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Usuário sem permissão para criar um albúm.',
              style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return;
      } else {
        action();
      }
    } else {
      _mostrarDialog('Erro', 'Usuário não está autenticado.');
    }
  }

  Future<void> _deletarAlbum(String nomeAlbum, String tipoAlbum) async {
    await FirebaseFirestore.instance
        .collection('work')
        .doc(widget.obra.id)
        .update({
      'albums': FieldValue.arrayRemove([
        {
          'name': nomeAlbum,
          'tipo': tipoAlbum
        } // Identificar o álbum pelo nome e tipo
      ])
    });
  }

  void _mostrarDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarConfirmacaoDeletar(String albumName, String tipoAlbum) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Deseja realmente excluir o álbum "$albumName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _verificarNivelAcesso(
                    () => _deletarAlbum(albumName, tipoAlbum));
                Navigator.of(context).pop();
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fotos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Álbuns',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('work')
                    .doc(widget.obra.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text(
                        'Nenhum álbum encontrado.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final data = snapshot.data!.data();
                  if (data == null || !data.containsKey('albums')) {
                    return const Center(
                      child: Text(
                        'Nenhum álbum encontrado.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final albums = data['albums'];
                  if (albums.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum álbum encontrado.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        String albumFullName = albums[index]['name'].toString();
                        String tipoAlbum = albums[index]['tipo'].toString();

                        return ListTile(
                          leading: const Icon(Icons.photo_album),
                          title: Text(albumFullName),
                          subtitle: Text('Tipo: $tipoAlbum'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NovaFotoScreen(
                                  albumName: albumFullName,
                                  obra: widget.obra,
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            _mostrarConfirmacaoDeletar(
                                albumFullName, tipoAlbum);
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Criar Novo Álbum',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _albumController,
                    decoration: const InputDecoration(
                      hintText: 'Nome do álbum',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _openDatePicker,
                  icon: const Icon(Icons.calendar_today),
                ),
                const SizedBox(width: 5),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down),
                  onSelected: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'Engenharia',
                        child: Text('Engenharia'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Ambiental',
                        child: Text('Ambiental'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'Social',
                        child: Text('Social'),
                      ),
                    ];
                  },
                ),
                const SizedBox(width: 5),
                ElevatedButton(
                  onPressed: () {
                    _verificarNivelAcesso(_criarAlbum);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text('Criar',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
