// ignore_for_file: use_build_context_synchronously, avoid_print, unnecessary_null_comparison
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sobral_app/pages/user_home.dart';

class Occurrence extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  const Occurrence({Key? key, required this.obra}) : super(key: key);

  @override
  State<Occurrence> createState() => _OccurrenceState();
}

class _OccurrenceState extends State<Occurrence> {
  final List<Map<String, dynamic>> _occurrenceData = [];
  final List<TextEditingController> _dateControllers = [];
  final List<TextEditingController> _descriptionControllers = [];
  final List<bool> _isCollapsedList = [];
  late String _userAccessLevel = '';

  @override
  void initState() {
    _showSavedData();
    super.initState();
    _fetchUserData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ocorrências',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Obra Selecionada: ${widget.obra['nome']} - ${widget.obra['num_contrato']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              for (int i = 0; i < _occurrenceData.length; i++)
                _buildOccurrenceBlock(i),
              const SizedBox(height: 5),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: _saveOccurrenceData,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: _addOccurrenceBlock,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOccurrenceBlock(int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey[200],
      ),
      padding: const EdgeInsets.only(left: 15.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.only(right: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Ocorrência ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteOccurrence(index);
                  },
                ),
                IconButton(
                  icon: _isCollapsedList[index]
                      ? const Icon(Icons.expand_more)
                      : const Icon(Icons.expand_less),
                  onPressed: () {
                    setState(() {
                      _isCollapsedList[index] = !_isCollapsedList[index];
                    });
                  },
                ),
              ],
            ),
            if (!_isCollapsedList[index]) ...[
              GestureDetector(
                onTap: () => _selectDate(context, _dateControllers[index]),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Data da Ocorrência',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _descriptionControllers[index],
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  void _addOccurrenceBlock() {
    setState(() {
      _occurrenceData.add({});
      _dateControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _isCollapsedList.add(false);
    });
  }

  Future<void> _saveOccurrenceData() async {
    try {
      List<String> permittedLevels = [
        'MASTER',
        'GESTOR',
        'AMBIENTAL',
      ];

      if (!permittedLevels.contains(_userAccessLevel)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Usuário sem permissão para salvar os dados de ocorrências.',
              style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return;
      }

      List<Map<String, dynamic>> updatedOccurrence = [];

      for (int i = 0; i < _occurrenceData.length; i++) {
        String date = _dateControllers[i].text.trim();
        String description = _descriptionControllers[i].text.trim();

        updatedOccurrence.add({
          'data': date,
          'descricao': description,
        });
      }

      await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .update({
        'ocorrencias': updatedOccurrence,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ocorrências atualizadas com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao atualizar as ocorrências: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _deleteOccurrence(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir?'),
          content:
              const Text('Tem certeza de que deseja excluir esta ocorrência?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _removeOccurrence(index);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _removeOccurrence(int index) async {
    try {
      if (_userAccessLevel == null) {
        print('Nível de acesso não carregado');
        return;
      }

      List<String> permittedLevels = [
        'MASTER',
        'AMBIENTAL',
      ];

      if (!permittedLevels.contains(_userAccessLevel)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Você não tem permissão para remover itens.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return;
      }

      await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .update({
        'ocorrencias': FieldValue.arrayRemove([_occurrenceData[index]])
      });

      setState(() {
        _occurrenceData.removeAt(index);
        _dateControllers[index].dispose();
        _descriptionControllers[index].dispose();
        _dateControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
        _isCollapsedList.removeAt(index);
      });

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ocorrência removida com sucesso!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao remover a ocorrência: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController dateController) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _showSavedData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('work')
          .doc(widget.obra.id)
          .get();

      List<dynamic>? occurrences = snapshot.data()?['ocorrencias'];
      if (occurrences != null) {
        setState(() {
          _occurrenceData.addAll(List<Map<String, dynamic>>.from(occurrences));
          for (var data in _occurrenceData) {
            TextEditingController dateController =
                TextEditingController(text: data['data']);
            TextEditingController descriptionController =
                TextEditingController(text: data['descricao']);

            _dateControllers.add(dateController);
            _descriptionControllers.add(descriptionController);
            _isCollapsedList.add(true);
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar as ocorrências: $e');
    }
  }
}
