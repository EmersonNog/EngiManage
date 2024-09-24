// ignore_for_file: use_build_context_synchronously, avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sobral_app/pages/user_home.dart';

class Crono extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  const Crono({super.key, required this.obra});

  @override
  State<Crono> createState() => _CronoState();
}

class _CronoState extends State<Crono> {
  List<Map<String, dynamic>> _cronoData = [];
  final List<TextEditingController> _monthYearControllers = [];
  final List<TextEditingController> _valueControllers = [];
  final List<bool> _isCollapsedList = [];
  late String _userAccessLevel = '';

  @override
  void initState() {
    super.initState();
    _loadCronoData();
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
          'Cronograma',
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
              for (int i = 0; i < _cronoData.length; i++) _buildCronoBlock(i),
              const SizedBox(height: 5),
              SizedBox(
                width: MediaQuery.of(context).size.width * 1,
                child: ElevatedButton(
                  onPressed: _saveCronoData,
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
        onPressed: _addCronoBlock,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  void _addCronoBlock() {
    setState(() {
      _cronoData.add({});
      TextEditingController monthYearController = TextEditingController();
      _monthYearControllers.add(monthYearController);
      _selectDate(context, monthYearController);
      _valueControllers.add(TextEditingController());
      _isCollapsedList.add(false);
    });
  }

  Widget _buildCronoBlock(int index) {
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
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Container(
        padding: const EdgeInsets.only(right: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Cronograma ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteCronoBlock(index);
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
                onTap: () => _selectDate(context, _monthYearControllers[index]),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _monthYearControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Mês do Pagamento',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onChanged: (newValue) {
                      _cronoData[index]['valor'] = newValue;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _valueControllers[index],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Valor'),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  void _saveCronoData() async {
    try {
      List<String> permittedLevels = [
        'MASTER',
        'GESTOR',
      ];

      if (!permittedLevels.contains(_userAccessLevel)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Usuário sem permissão para salvar os dados de cronograma.',
              style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return;
      }

      List<Map<String, dynamic>> updatedCrono = [];

      for (int i = 0; i < _cronoData.length; i++) {
        String monthYear = _monthYearControllers[i].text.trim();
        String value = _valueControllers[i].text.trim();

        updatedCrono.add({
          'data': monthYear,
          'valor': value,
        });
      }

      await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .update({
        'cronograma': updatedCrono,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dados de pagamento atualizados com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao atualizar os dados de pagamento: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _deleteCronoBlock(int index) {
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
                _removeCronoBlock(index);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _removeCronoBlock(int index) async {
    List<String> permittedLevels = [
      'MASTER',
    ];

    if (!permittedLevels.contains(_userAccessLevel)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Usuário sem permissão para excluir os dados de cronograma.',
            style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
      return;
    }
    try {
      String docId = widget.obra.id;

      await FirebaseFirestore.instance.collection('work').doc(docId).update({
        'cronograma': FieldValue.arrayRemove([_cronoData[index]])
      });

      setState(() {
        _cronoData.removeAt(index);
        _monthYearControllers[index].dispose();
        _monthYearControllers.removeAt(index);
        _valueControllers[index].dispose();
        _valueControllers.removeAt(index);
        _isCollapsedList.removeAt(index);
      });

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Item excluído com sucesso!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print('Error deleting crono block: $e');
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController monthYearController) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        monthYearController.text = DateFormat('MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _loadCronoData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('work')
          .doc(widget.obra.id)
          .get();

      List<dynamic>? crono = snapshot.data()?['cronograma'];
      if (crono != null) {
        setState(() {
          _cronoData = List<Map<String, dynamic>>.from(crono);
          for (var crono in _cronoData) {
            _monthYearControllers.add(TextEditingController(
              text: crono['data'],
            ));
            _valueControllers.add(TextEditingController(
              text: crono['valor'],
            ));
            _isCollapsedList.add(true);
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar os dados de pagamento: $e');
    }
  }
}
