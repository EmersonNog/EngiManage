// ignore_for_file: use_build_context_synchronously, avoid_print, unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sobral_app/pages/user_home.dart';

class Licesing extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  const Licesing({super.key, required this.obra});

  @override
  State<Licesing> createState() => _LicesingState();
}

class _LicesingState extends State<Licesing> {
  final List<Map<String, dynamic>> _licensingData = [];
  final List<TextEditingController> _pdfControllers = [];
  final List<TextEditingController> _tipoControllers = [];
  final List<TextEditingController> _numeroControllers = [];
  final List<TextEditingController> _validadeControllers = [];
  final List<TextEditingController> _observacoesControllers = [];
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
  void dispose() {
    for (var controller in [
      ..._pdfControllers,
      ..._tipoControllers,
      ..._numeroControllers,
      ..._validadeControllers,
      ..._observacoesControllers
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Licenças',
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
              for (int i = 0; i < _licensingData.length; i++)
                _buildLicensingBlock(i),
              const SizedBox(height: 5),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: _saveLicensingData,
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
        onPressed: _addLicensingBlock,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLicensingBlock(int index) {
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
                  'Licença ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    _deleteLicensingBlock(index);
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
              TextFormField(
                controller: _tipoControllers[index],
                decoration: const InputDecoration(labelText: 'Tipo de Licença'),
              ),
              TextFormField(
                controller: _numeroControllers[index],
                decoration: const InputDecoration(labelText: 'Nº da Licença'),
              ),
              GestureDetector(
                onTap: () => _selectDate(context, _validadeControllers[index]),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _validadeControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Validade',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _observacoesControllers[index],
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
              TextFormField(
                controller: _pdfControllers[index],
                decoration: const InputDecoration(labelText: 'Anexo'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addLicensingBlock() {
    setState(() {
      _licensingData.add({});
      _pdfControllers.add(TextEditingController());
      _tipoControllers.add(TextEditingController());
      _numeroControllers.add(TextEditingController());
      _validadeControllers.add(TextEditingController());
      _observacoesControllers.add(TextEditingController());
      _isCollapsedList.add(false);
    });
  }

  Future<void> _saveLicensingData() async {
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

      List<Map<String, dynamic>> updatedLicensing = [];

      for (int i = 0; i < _licensingData.length; i++) {
        String pdf = _pdfControllers[i].text.trim();
        String tipo = _tipoControllers[i].text.trim();
        String numero = _numeroControllers[i].text.trim();
        String validade = _validadeControllers[i].text.trim();
        String observacoes = _observacoesControllers[i].text.trim();

        updatedLicensing.add({
          'pdf': pdf,
          'tipo': tipo,
          'numero': numero,
          'validade': validade,
          'observacoes': observacoes,
        });
      }

      await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .update({
        'licencas': updatedLicensing,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Licenças atualizadas com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao atualizar as licenças: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _deleteLicensingBlock(int index) {
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
                _removerLicenca(index);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _removerLicenca(int index) async {
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

      final obraId = widget.obra.id;
      final documentReference =
          FirebaseFirestore.instance.collection('work').doc(obraId);

      final snapshot = await documentReference.get();
      final data = snapshot.data();

      if (data != null && data['licencas'] != null) {
        List<Map<String, dynamic>> licencas =
            List<Map<String, dynamic>>.from(data['licencas']);
        licencas.removeAt(index);

        await documentReference.update({'licencas': licencas});
      }

      setState(() {
        _licensingData.removeAt(index);
        _pdfControllers[index].dispose();
        _tipoControllers[index].dispose();
        _numeroControllers[index].dispose();
        _validadeControllers[index].dispose();
        _observacoesControllers[index].dispose();
        _isCollapsedList.removeAt(index);
        _pdfControllers.removeAt(index);
        _tipoControllers.removeAt(index);
        _numeroControllers.removeAt(index);
        _validadeControllers.removeAt(index);
        _observacoesControllers.removeAt(index);
      });

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Licença excluída com sucesso!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir a licença: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
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

      List<dynamic>? licencas = snapshot.data()?['licencas'];
      if (licencas != null) {
        setState(() {
          _licensingData.addAll(List<Map<String, dynamic>>.from(licencas));
          for (var data in _licensingData) {
            _pdfControllers.add(TextEditingController(text: data['pdf']));
            _tipoControllers.add(TextEditingController(text: data['tipo']));
            _numeroControllers.add(TextEditingController(text: data['numero']));
            _validadeControllers
                .add(TextEditingController(text: data['validade']));
            _observacoesControllers
                .add(TextEditingController(text: data['observacoes']));

            _isCollapsedList.add(true);
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar as licenças: $e');
    }
  }
}
