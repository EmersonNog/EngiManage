// ignore_for_file: use_build_context_synchronously, avoid_print, unnecessary_null_comparison
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sobral_app/pages/user_home.dart';

class Quantitative extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  const Quantitative({super.key, required this.obra});

  @override
  State<Quantitative> createState() => _QuantitativeState();
}

class _QuantitativeState extends State<Quantitative> {
  List<Map<String, dynamic>> _quantitativeData = [];
  final List<TextEditingController> _dateControllers = [];
  final List<TextEditingController> _ramalPedrialControllers = [];
  final List<TextEditingController> _imoveisLigadosControllers = [];
  final List<TextEditingController> _redeEsgotoControllers = [];
  final List<TextEditingController> _pisoIntertravadoControllers = [];
  final List<TextEditingController> _pisoPedraToscaControllers = [];
  final List<TextEditingController> _pavimentacaoAsfalticaControllers = [];
  final List<TextEditingController> _estElevatoriaControllers = [];
  final List<TextEditingController> _estTratamentoControllers = [];
  final List<TextEditingController> _tuboControllers = [];
  final List<TextEditingController> _galeriaControllers = [];
  final List<bool> _isCollapsedList = [];
  late String _userAccessLevel = '';

  @override
  void initState() {
    super.initState();
    _loadQuantitativeData();
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

  Future<void> _loadQuantitativeData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('work')
          .doc(widget.obra.id)
          .get();

      List<dynamic>? quantitatives = snapshot.data()?['quantitatives'];
      if (quantitatives != null) {
        setState(() {
          _quantitativeData = List<Map<String, dynamic>>.from(quantitatives);
          for (var quantitative in _quantitativeData) {
            _dateControllers
                .add(TextEditingController(text: quantitative['date']));
            _ramalPedrialControllers.add(
                TextEditingController(text: quantitative['ramal_pedrial']));
            _estElevatoriaControllers.add(TextEditingController(
                text: quantitative['estacao_elevatoria']));
            _estTratamentoControllers.add(TextEditingController(
                text: quantitative['estacao_tratamento']));
            _imoveisLigadosControllers.add(
                TextEditingController(text: quantitative['imoveis_ligados']));
            _redeEsgotoControllers
                .add(TextEditingController(text: quantitative['rede_esgoto']));
            _pisoIntertravadoControllers.add(
                TextEditingController(text: quantitative['piso_intertravado']));
            _pisoPedraToscaControllers.add(
                TextEditingController(text: quantitative['piso_pedra_tosca']));
            _pavimentacaoAsfalticaControllers.add(TextEditingController(
                text: quantitative['pavimentacao_asfaltica']));
            _tuboControllers
                .add(TextEditingController(text: quantitative['tubo']));
            _galeriaControllers
                .add(TextEditingController(text: quantitative['galeria']));
            _isCollapsedList.add(true);
          }
        });
      }
    } catch (e) {
      print('Erro ao carregar os dados quantitativos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dados Quantitativos',
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
              for (int i = 0; i < _quantitativeData.length; i++)
                _buildQuantitativeBlock(i),
              const SizedBox(height: 5),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: _saveQuantitativeData,
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
        onPressed: _addQuantitativeBlock,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuantitativeBlock(int index) {
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
                  'Quantitativo ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () =>
                      _confirmDeleteQuantitativeBlock(context, index),
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
              if (widget.obra['contrato']['tipo_obra'] ==
                  "SISTEMA DE ESGOTAMENTO SANITÁRIO") ...[
                GestureDetector(
                  onTap: () => _selectDate(context, _dateControllers[index]),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateControllers[index],
                      decoration: const InputDecoration(
                        labelText: 'Data (mm/aaaa)',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _ramalPedrialControllers[index],
                  decoration:
                      const InputDecoration(labelText: 'Ramal Predial (unid)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _imoveisLigadosControllers[index],
                  decoration: const InputDecoration(
                      labelText: 'Imóveis ligados à rede (unid)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _estElevatoriaControllers[index],
                  decoration: const InputDecoration(
                      labelText: 'Estação Elevatória de Esgoto (unid)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _estTratamentoControllers[index],
                  decoration: const InputDecoration(
                      labelText: 'Estação de Tratamento de Esgoto (unid)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _redeEsgotoControllers[index],
                  decoration:
                      const InputDecoration(labelText: 'Rede de esgoto (m)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _pisoIntertravadoControllers[index],
                  decoration: const InputDecoration(
                      labelText: 'Piso Intertravado (m²)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _pisoPedraToscaControllers[index],
                  decoration: const InputDecoration(
                      labelText: 'Piso em pedra tosca (m²)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _pavimentacaoAsfalticaControllers[index],
                  decoration: const InputDecoration(
                      labelText: 'Pavimentação asfáltica (m²)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
              ],
              if (widget.obra['contrato']['tipo_obra'] ==
                  "DRENAGEM PLUVIAL") ...[
                GestureDetector(
                  onTap: () => _selectDate(context, _dateControllers[index]),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateControllers[index],
                      decoration: const InputDecoration(
                        labelText: 'Data (mm/aaaa)',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                TextFormField(
                  controller: _tuboControllers[index],
                  decoration: const InputDecoration(labelText: 'Tubo (m)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _galeriaControllers[index],
                  decoration: const InputDecoration(labelText: 'Galeria (m)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _pisoIntertravadoControllers[index],
                  decoration: const InputDecoration(
                      labelText: 'Piso Intertravado (m²)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _pisoPedraToscaControllers[index],
                  decoration: const InputDecoration(
                      labelText: 'Piso em pedra tosca (m²)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _pavimentacaoAsfalticaControllers[index],
                  decoration: const InputDecoration(
                      labelText: 'Pavimentação asfáltica (m²)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
              ]
            ],
          ],
        ),
      ),
    );
  }

  void _addQuantitativeBlock() {
    setState(() {
      _quantitativeData.add({});
      _dateControllers.add(TextEditingController());
      _ramalPedrialControllers.add(TextEditingController());
      _estElevatoriaControllers.add(TextEditingController());
      _estTratamentoControllers.add(TextEditingController());
      _imoveisLigadosControllers.add(TextEditingController());
      _redeEsgotoControllers.add(TextEditingController());
      _pisoIntertravadoControllers.add(TextEditingController());
      _pisoPedraToscaControllers.add(TextEditingController());
      _pavimentacaoAsfalticaControllers.add(TextEditingController());
      _tuboControllers.add(TextEditingController());
      _galeriaControllers.add(TextEditingController());
      _isCollapsedList.add(false);
    });
  }

  Future<void> _saveQuantitativeData() async {
    try {
      List<String> permittedLevels = [
        'MASTER',
        'GESTOR',
      ];

      if (!permittedLevels.contains(_userAccessLevel)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Usuário sem permissão para salvar os dados de quantitativos.',
              style: TextStyle(color: Colors.white)),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return;
      }

      List<Map<String, dynamic>> updatedQuantitatives = [];

      for (int i = 0; i < _quantitativeData.length; i++) {
        Map<String, dynamic> quantitative = {};
        if (widget.obra['contrato']['tipo_obra'] ==
            "SISTEMA DE ESGOTAMENTO SANITÁRIO") {
          quantitative.addAll({
            'date': _dateControllers[i].text.trim(),
            'ramal_pedrial': _ramalPedrialControllers[i].text.trim(),
            'estacao_elevatoria': _estElevatoriaControllers[i].text.trim(),
            'estacao_tratamento': _estTratamentoControllers[i].text.trim(),
            'imoveis_ligados': _imoveisLigadosControllers[i].text.trim(),
            'rede_esgoto': _redeEsgotoControllers[i].text.trim(),
            'piso_intertravado': _pisoIntertravadoControllers[i].text.trim(),
            'piso_pedra_tosca': _pisoPedraToscaControllers[i].text.trim(),
            'pavimentacao_asfaltica':
                _pavimentacaoAsfalticaControllers[i].text.trim(),
            'tubo': _tuboControllers[i].text.trim(),
            'galeria': _galeriaControllers[i].text.trim(),
          });
        }
        if (widget.obra['contrato']['tipo_obra'] ==
            "REDE DE DRENAGEM PLUVIAL") {
          quantitative.addAll({
            'date': _dateControllers[i].text.trim(),
            'tubo': _tuboControllers[i].text.trim(),
            'galeria': _galeriaControllers[i].text.trim(),
            'piso_intertravado': _pisoIntertravadoControllers[i].text.trim(),
            'piso_pedra_tosca': _pisoPedraToscaControllers[i].text.trim(),
            'pavimentacao_asfaltica':
                _pavimentacaoAsfalticaControllers[i].text.trim(),
          });
        }
        updatedQuantitatives.add(quantitative);
      }

      await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .update({
        'quantitatives': updatedQuantitatives,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dados quantitativos salvos com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao atualizar os dados quantitativos: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _confirmDeleteQuantitativeBlock(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Excluir bloco quantitativo"),
          content: const Text(
              "Tem certeza de que deseja excluir este bloco quantitativo?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                _deleteQuantitativeBlock(index);
              },
              child: const Text("Excluir"),
            ),
          ],
        );
      },
    );
  }

  void _deleteQuantitativeBlock(int index) async {
    try {
      if (_userAccessLevel == null) {
        print('Nível de acesso não carregado');
        return;
      }

      List<String> permittedLevels = [
        'MASTER',
      ];

      if (!permittedLevels.contains(_userAccessLevel)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Você não tem permissão para remover itens.'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
        return;
      }

      List<Map<String, dynamic>> updatedQuantitatives =
          List<Map<String, dynamic>>.from(_quantitativeData);
      updatedQuantitatives.removeAt(index);

      await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .update({
        'quantitatives': updatedQuantitatives,
      });

      setState(() {
        _quantitativeData = updatedQuantitatives;
        _dateControllers[index].dispose();
        _dateControllers.removeAt(index);
        _ramalPedrialControllers[index].dispose();
        _ramalPedrialControllers.removeAt(index);
        _estElevatoriaControllers[index].dispose();
        _estElevatoriaControllers.removeAt(index);
        _estTratamentoControllers[index].dispose();
        _estTratamentoControllers.removeAt(index);
        _imoveisLigadosControllers[index].dispose();
        _imoveisLigadosControllers.removeAt(index);
        _redeEsgotoControllers[index].dispose();
        _redeEsgotoControllers.removeAt(index);
        _pisoIntertravadoControllers[index].dispose();
        _pisoIntertravadoControllers.removeAt(index);
        _pisoPedraToscaControllers[index].dispose();
        _pisoPedraToscaControllers.removeAt(index);
        _pavimentacaoAsfalticaControllers[index].dispose();
        _pavimentacaoAsfalticaControllers.removeAt(index);
        _tuboControllers[index].dispose();
        _tuboControllers.removeAt(index);
        _galeriaControllers[index].dispose();
        _galeriaControllers.removeAt(index);
        _isCollapsedList.removeAt(index);
      });

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bloco quantitativo excluído com sucesso!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao excluir bloco quantitativo: $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.black,
            colorScheme: const ColorScheme.light(primary: Colors.black),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      setState(() {
        controller.text = DateFormat('MM/yyyy').format(selectedDate);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _dateControllers) {
      controller.dispose();
    }
    for (var controller in _ramalPedrialControllers) {
      controller.dispose();
    }
    for (var controller in _estElevatoriaControllers) {
      controller.dispose();
    }
    for (var controller in _estTratamentoControllers) {
      controller.dispose();
    }
    for (var controller in _imoveisLigadosControllers) {
      controller.dispose();
    }
    for (var controller in _redeEsgotoControllers) {
      controller.dispose();
    }
    for (var controller in _pisoIntertravadoControllers) {
      controller.dispose();
    }
    for (var controller in _pisoPedraToscaControllers) {
      controller.dispose();
    }
    for (var controller in _pavimentacaoAsfalticaControllers) {
      controller.dispose();
    }
    for (var controller in _tuboControllers) {
      controller.dispose();
    }
    for (var controller in _galeriaControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
