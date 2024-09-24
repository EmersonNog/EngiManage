// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo.dart';

class NovaFotoScreen extends StatefulWidget {
  final String albumName;
  final QueryDocumentSnapshot obra;

  const NovaFotoScreen({
    Key? key,
    required this.albumName,
    required this.obra,
  }) : super(key: key);

  @override
  _NovaFotoScreenState createState() => _NovaFotoScreenState();
}

class _NovaFotoScreenState extends State<NovaFotoScreen> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _servicosController = TextEditingController();
  File? _image;
  late String _userAccessLevel = '';
  bool _isEngenharia = false;
  final picker = ImagePicker();

  bool _uploading = false;
  bool _uploadSuccess = false;

  @override
  void initState() {
    super.initState();
    _checkAlbumTipo();
    _fetchUserData();
  }

  Future<void> _checkAlbumTipo() async {
    try {
      // Verifica se o álbum atual possui o tipo "Engenharia"
      List<dynamic> albums = widget.obra['albums'];
      for (var album in albums) {
        if (album['name'] == widget.albumName &&
            album['tipo'] == 'Engenharia') {
          setState(() {
            _isEngenharia = true;
          });
          break;
        }
      }
    } catch (error) {
      print('Erro ao verificar o tipo do álbum: $error');
    }
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

  Future getImageFromCamera() async {
    await _getImage(ImageSource.camera);
  }

  Future getImageFromGallery() async {
    await _getImage(ImageSource.gallery);
  }

  Future<void> _getImage(ImageSource source) async {
    List<String> permittedLevels = [
      'MASTER',
      'GESTOR',
      'ENGENHARIA',
      'SOCIAL',
      'AMBIENTAL'
    ];

    if (permittedLevels.contains(_userAccessLevel)) {
      final pickedFile = await picker.pickImage(source: source);

      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {
          print('Nenhuma imagem selecionada.');
        }
      });
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text('Você não tem permissão para tirar fotos.'),
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
  }

  Future<String?> _uploadImage() async {
    if (_image == null) {
      return null;
    }

    final fileName = _image!.path.split('/').last; // Obtém o nome do arquivo
    final destination = 'albums/${widget.albumName}/$fileName';

    try {
      setState(() {
        _uploading = true;
      });

      await firebase_storage.FirebaseStorage.instance
          .ref(destination)
          .putFile(_image!);

      final url = await firebase_storage.FirebaseStorage.instance
          .ref(destination)
          .getDownloadURL();

      final photoId = fileName;

      await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .update({
        'photos': FieldValue.arrayUnion([
          {
            'comment': _commentController.text,
            'photoId': photoId,
            'imageUrl': url,
            'albumName': widget.albumName,
            'services': _servicosController.text,
          }
        ])
      });

      setState(() {
        _image = null;
        _uploading = false;
        _commentController.clear();
        _servicosController.clear();
      });

      return url;
    } on firebase_storage.FirebaseException catch (e) {
      print('Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<void> _uploadAndAddImage() async {
    if (_image == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text('Por favor, tire uma foto antes de enviar.'),
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
      return;
    }

    try {
      final imageUrl = await _uploadImage();

      if (imageUrl != null) {
        setState(() {
          _uploading = false;
          _uploadSuccess = true;
          _image = null;
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _uploadSuccess = false;
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Erro'),
              content: const Text('Falha ao fazer upload da imagem.'),
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
    } catch (e) {
      print('Erro ao atualizar o documento da obra: $e');
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                'Erro ao enviar a foto. Tente novamente mais tarde.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.albumName),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _image == null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comentário (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (_isEngenharia)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextField(
                    controller: _servicosController,
                    decoration: const InputDecoration(
                      labelText: 'Serviços',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: getImageFromCamera,
            tooltip: 'Tirar Foto',
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: getImageFromGallery,
            tooltip: 'Escolher da Galeria',
            child: const Icon(Icons.photo_library, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _uploading
              ? FloatingActionButton(
                  backgroundColor: Colors.black,
                  onPressed: () {},
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _uploadSuccess
                  ? FloatingActionButton(
                      onPressed: () {},
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.check, color: Colors.white),
                    )
                  : FloatingActionButton(
                      backgroundColor: Colors.black,
                      onPressed: _uploadAndAddImage,
                      tooltip: 'Enviar Foto',
                      child:
                          const Icon(Icons.cloud_upload, color: Colors.white),
                    ),
          const SizedBox(height: 16),
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListaImagensScreen(
                    albumName: widget.albumName,
                  ),
                ),
              );
            },
            tooltip: 'Ver Imagens',
            child: const Icon(Icons.image_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
