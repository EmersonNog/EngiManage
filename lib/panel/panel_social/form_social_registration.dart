// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously, avoid_print, unnecessary_null_comparison
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sobral_app/pages/user_home.dart'; // Importado para formatação de data

class SocialRegistration extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  const SocialRegistration({Key? key, required this.obra});

  @override
  State<SocialRegistration> createState() => _SocialRegistrationState();
}

class _SocialRegistrationState extends State<SocialRegistration> {
  final List<Map<String, dynamic>> _productionData = [];
  final List<TextEditingController> _dateControllers = [];
  final List<TextEditingController> _accumulatedRegistersControllers = [];
  final List<TextEditingController> _accumulatedTermsControllers = [];
  final List<bool> _isCollapsedList = [];
  late String _userAccessLevel = '';

  @override
  void initState() {
    super.initState();
    _showSavedData();
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
          'Cadastro Social',
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
              for (int i = 0; i < _productionData.length; i++)
                _buildProductionBlock(i),
              const SizedBox(height: 5),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: _saveProductionData,
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
        onPressed: _addProductionBlock,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductionBlock(int index) {
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
                  'Cadastro Social ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteDialog(index);
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
                      labelText: 'Data de Cadastro',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _accumulatedRegistersControllers[index],
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Cadastros Acumulados'),
              ),
              TextFormField(
                controller: _accumulatedTermsControllers[index],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Termos de Adesão Acumulados'),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  void _addProductionBlock() {
    setState(() {
      _productionData.add({});
      _dateControllers.add(TextEditingController());
      _accumulatedRegistersControllers.add(TextEditingController());
      _accumulatedTermsControllers.add(TextEditingController());
      _isCollapsedList.add(false);
    });
  }

  Future<void> _saveProductionData() async {
    try {
      List<String> permittedLevels = [
        'MASTER',
        'GESTOR',
        'SOCIAL',
      ];

      if (!permittedLevels.contains(_userAccessLevel)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Usuário sem permissão para salvar os dados de cadastros.',
              style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return;
      }

      List<Map<String, dynamic>> updatedProduction = [];

      for (int i = 0; i < _productionData.length; i++) {
        String date = _dateControllers[i].text.trim();
        int accumulatedRegisters =
            int.tryParse(_accumulatedRegistersControllers[i].text.trim()) ?? 0;
        int accumulatedTerms =
            int.tryParse(_accumulatedTermsControllers[i].text.trim()) ?? 0;

        updatedProduction.add({
          'data': date,
          'cadastroAcumulado': accumulatedRegisters,
          'termosAcumulados': accumulatedTerms,
        });
      }

      await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .update({
        'cadastro_social': updatedProduction,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dados de cadastro social atualizados com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao atualizar os dados de cadastro social: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _deleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir?'),
          content: const Text('Tem certeza de que deseja excluir este item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _removeProductionBlock(index);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _removeProductionBlock(int index) async {
    if (_userAccessLevel == null) {
      print('Nível de acesso não carregado');
      return;
    }

    List<String> permittedLevels = [
      'MASTER',
      'SOCIAL',
    ];

    if (!permittedLevels.contains(_userAccessLevel)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Você não tem permissão para remover itens.'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() {
      _productionData.removeAt(index);
      _dateControllers.removeAt(index);
      _accumulatedRegistersControllers.removeAt(index);
      _accumulatedTermsControllers.removeAt(index);
      _isCollapsedList.removeAt(index);
    });

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('work')
          .doc(widget.obra.id)
          .get();

      List<dynamic>? production = snapshot.data()?['cadastro_social'];

      if (production != null) {
        production.removeAt(index);

        await FirebaseFirestore.instance
            .collection('work')
            .doc(widget.obra.id)
            .update({'cadastro_social': production});

        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const UserHome(),
        ));

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Item removido com sucesso!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      print('Erro ao remover o item do Firestore: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao remover o item: $e'),
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

      List<dynamic>? production = snapshot.data()?['cadastro_social'];
      if (production != null) {
        setState(() {
          _productionData.addAll(List<Map<String, dynamic>>.from(production));
          for (var data in _productionData) {
            TextEditingController dateController =
                TextEditingController(text: data['data']);
            TextEditingController registersController = TextEditingController(
                text: data['cadastroAcumulado'].toString());
            TextEditingController accumulatedTermsController =
                TextEditingController(
                    text: data['termosAcumulados'].toString());

            _dateControllers.add(dateController);
            _accumulatedRegistersControllers.add(registersController);
            _accumulatedTermsControllers.add(accumulatedTermsController);
            _isCollapsedList.add(true);
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar os dados de cadastro social: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _dateControllers) {
      controller.dispose();
    }
    for (var controller in _accumulatedRegistersControllers) {
      controller.dispose();
    }
    for (var controller in _accumulatedTermsControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
