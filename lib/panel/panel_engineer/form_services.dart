// ignore_for_file: use_build_context_synchronously, avoid_print, unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../pages/user_home.dart';

class Services extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  const Services({super.key, required this.obra});

  @override
  State<Services> createState() => _ServicesState();
}

class _ServicesState extends State<Services> {
  List<Map<String, dynamic>> _servicesData = [];
  final List<TextEditingController> _dateControllers = [];
  final List<TextEditingController> _descriptionControllers = [];
  final List<TextEditingController> _anotationControllers = [];
  final List<bool> _isCollapsedList = [];
  late String _userAccessLevel = '';

  @override
  void initState() {
    super.initState();
    _loadServicesData();
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

  Future<void> _loadServicesData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('work')
          .doc(widget.obra.id)
          .get();

      List<dynamic>? services = snapshot.data()?['services'];
      if (services != null) {
        setState(() {
          _servicesData = List<Map<String, dynamic>>.from(services);
          _servicesData.forEach((service) {
            _dateControllers.add(TextEditingController(
              text: service['data_servico'],
            ));
            _descriptionControllers.add(TextEditingController(
              text: service['descricao'],
            ));
            _anotationControllers.add(TextEditingController(
              text: service['anotacao'],
            ));
            _isCollapsedList.add(true);
          });
        });
      }
    } catch (e) {
      print('Erro ao carregar os dados de serviços: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Serviços',
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
              for (int i = 0; i < _servicesData.length; i++)
                _buildServiceBlock(i),
              const SizedBox(height: 5),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: _saveServiceData,
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
        onPressed: _addServiceBlock,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildServiceBlock(int index) {
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
                  'Serviço ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteServiceBlock(index);
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
                      labelText: 'Data do Serviço',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _descriptionControllers[index],
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              TextFormField(
                controller: _anotationControllers[index],
                decoration: const InputDecoration(labelText: 'Anotações'),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  void _addServiceBlock() {
    setState(() {
      _servicesData.add({});
      _dateControllers.add(TextEditingController());
      _descriptionControllers.add(TextEditingController());
      _anotationControllers.add(TextEditingController());
      _isCollapsedList.add(false);
    });
  }

  Future<void> _saveServiceData() async {
    try {
      List<String> permittedLevels = [
        'MASTER',
        'GESTOR',
        'ENGENHARIA',
      ];

      if (!permittedLevels.contains(_userAccessLevel)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Usuário sem permissão para salvar os dados de serviços.',
              style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return;
      }

      List<Map<String, dynamic>> updatedServices = [];

      for (int i = 0; i < _servicesData.length; i++) {
        String date = _dateControllers[i].text.trim();
        String description = _descriptionControllers[i].text.trim();
        String anotation = _anotationControllers[i].text.trim();

        updatedServices.add({
          'data_servico': date,
          'descricao': description,
          'anotacao': anotation,
        });
      }

      await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .update({
        'services': updatedServices,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dados de serviço atualizados com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao atualizar os dados de serviço: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _deleteServiceBlock(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir?'),
          content:
              const Text('Tem certeza de que deseja excluir este serviço?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _removeServiceBlock(index);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _removeServiceBlock(int index) async {
    try {
      if (_userAccessLevel == null) {
        print('Nível de acesso não carregado');
        return;
      }

      List<String> permittedLevels = [
        'MASTER',
        'ENGENHARIA',
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
        _servicesData.removeAt(index);
        _dateControllers.removeAt(index);
        _descriptionControllers.removeAt(index);
        _anotationControllers.removeAt(index);
        _isCollapsedList.removeAt(index);
      });

      DocumentReference<Map<String, dynamic>> documentReference =
          FirebaseFirestore.instance.collection('work').doc(widget.obra.id);

      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await documentReference.get();

      List<dynamic> updatedServices = List.from(snapshot.data()?['services']);
      updatedServices.removeAt(index);

      await documentReference.update({'services': updatedServices});

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Serviço removido com sucesso!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao remover o serviço: $e'),
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

  @override
  void dispose() {
    for (var controller in _dateControllers) {
      controller.dispose();
    }
    for (var controller in _descriptionControllers) {
      controller.dispose();
    }
    for (var controller in _anotationControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
