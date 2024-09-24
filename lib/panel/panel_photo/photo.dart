// ignore_for_file: use_build_context_synchronously, avoid_function_literals_in_foreach_calls, unnecessary_cast, library_private_types_in_public_api, avoid_print

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class ListaImagensScreen extends StatefulWidget {
  final String albumName;

  const ListaImagensScreen({
    Key? key,
    required this.albumName,
  }) : super(key: key);

  @override
  _ListaImagensScreenState createState() => _ListaImagensScreenState();
}

class _ListaImagensScreenState extends State<ListaImagensScreen> {
  late Future<List<Map<String, dynamic>>> _imageData;
  final List<String> _selectedImageUrls = [];
  final double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _imageData = _loadImageData();
  }

  Future<List<Map<String, dynamic>>> _loadImageData() async {
    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('work').get();
      final List<Map<String, dynamic>> imageData = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final photos = data['photos'];
        if (photos != null && photos is List<dynamic>) {
          for (var photo in photos) {
            if (photo['albumName'] == widget.albumName) {
              final photoData = {
                'imageUrl': photo['imageUrl'],
                'albumName': photo['albumName'],
                'photoComment': photo['comment'] ?? '',
                'services': photo['services'] ?? '' // Add services field
              };
              imageData.add(photoData);
            }
          }
        }
      }
      return imageData;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveSelectedImagesToGallery() async {
    try {
      for (String imageUrl in _selectedImageUrls) {
        final HttpClient httpClient = HttpClient();
        final HttpClientRequest request =
            await httpClient.getUrl(Uri.parse(imageUrl));
        final HttpClientResponse response = await request.close();

        if (response.statusCode == 200) {
          final Uint8List bytes =
              await consolidateHttpClientResponseBytes(response);

          final result =
              await ImageGallerySaver.saveImage(Uint8List.fromList(bytes));

          if (result['isSuccess'] == true) {
            print('Image saved to gallery');
          } else {
            throw Exception('Failed to save image to gallery');
          }
        } else {
          throw Exception('Failed to download image: ${response.statusCode}');
        }
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Saved Successfully'),
            content: const Text('Selected images saved to gallery.'),
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
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save images to gallery: $e'),
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

  void _deleteSelectedImages() async {
    try {
      for (String imageUrl in _selectedImageUrls) {
        await FirebaseFirestore.instance
            .collection('work')
            .get()
            .then((querySnapshot) {
          querySnapshot.docs.forEach((doc) async {
            final data = doc.data() as Map<String, dynamic>;
            final photos = data['photos'] as List<dynamic>;
            for (var photo in photos) {
              if (photo['imageUrl'] == imageUrl) {
                await FirebaseFirestore.instance
                    .collection('work')
                    .doc(doc.id)
                    .update({
                  'photos': FieldValue.arrayRemove([photo])
                });
                break;
              }
            }
          });
        });

        // Deleta a imagem do Firebase Storage
        final firebaseStorageRef =
            firebase_storage.FirebaseStorage.instance.refFromURL(imageUrl);
        await firebaseStorageRef.delete();
      }

      setState(() {
        _selectedImageUrls.clear();
      });

      setState(() {
        _imageData = _loadImageData();
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Erro'),
            content: const Text(
                'Erro ao excluir imagens. Tente novamente mais tarde.'),
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

  void _toggleImageSelection(String imageUrl) {
    setState(() {
      if (_selectedImageUrls.contains(imageUrl)) {
        _selectedImageUrls.remove(imageUrl);
      } else {
        _selectedImageUrls.add(imageUrl);
      }
    });
  }

  void _showMaximizedImage(BuildContext context, String imageUrl,
      String description, String services) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                color: Colors.black,
                constraints: const BoxConstraints(
                    maxHeight: 200), // Altura máxima definida
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Descrição:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.fade,
                      ),
                      const SizedBox(height: 8.0),
                      const Text(
                        'Serviços:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        services,
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.fade,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildError(dynamic error) {
    return Center(child: Text('Error loading images: $error'));
  }

  Widget _buildProgressIndicator() {
    return LinearProgressIndicator(
      value: _downloadProgress,
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
    );
  }

  void _confirmDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text(
              'Tem certeza de que deseja excluir as imagens selecionadas?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
                _deleteSelectedImages(); // Exclui as imagens
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> imageData) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: imageData.length,
      itemBuilder: (context, index) {
        final data = imageData[index];
        final imageUrl = data['imageUrl'];
        final isSelected = _selectedImageUrls.contains(imageUrl);
        return GestureDetector(
          onDoubleTap: () {
            _toggleImageSelection(imageUrl);
          },
          onLongPress: () {
            _showMaximizedImage(
                context, imageUrl, data['photoComment'], data['services']);
          },
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 1,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Descrição: ${data['photoComment']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Álbum: ${data['albumName']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Serviços: ${data['services']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meu álbum"),
        actions: [
          if (_selectedImageUrls.isNotEmpty)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _selectedImageUrls.isNotEmpty
                      ? () => _confirmDeleteDialog(context)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.black),
                  onPressed: _selectedImageUrls.isNotEmpty
                      ? () => _saveSelectedImagesToGallery()
                      : null,
                ),
              ],
            )
        ],
      ),
      body: Column(
        children: [
          if (_downloadProgress > 0.0) _buildProgressIndicator(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _imageData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoading();
                } else if (snapshot.hasError) {
                  return _buildError(snapshot.error);
                } else {
                  final List<Map<String, dynamic>> imageData =
                      snapshot.data ?? [];
                  return _buildGrid(imageData);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
