// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, avoid_print, unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../pages/user_home.dart';

class FormWorkScreen extends StatefulWidget {
  final QueryDocumentSnapshot obra;

  const FormWorkScreen({Key? key, required this.obra}) : super(key: key);

  @override
  _FormWorkScreenState createState() => _FormWorkScreenState();
}

class _FormWorkScreenState extends State<FormWorkScreen> {
  final List<TextEditingController> _extendedDeadlineControllers = [];
  final List<TextEditingController> _acrescimoControllers = [];
  final List<TextEditingController> _contractorNameControllers = [];
  final List<TextEditingController> _dataAssinaturaControllers = [];
  final List<TextEditingController> _dataPublicacaoControllers = [];
  final List<TextEditingController> _supressaoControllers = [];
  final List<TextEditingController> _repercussaoControllers = [];
  final List<TextEditingController> _diasVigenciaControllers = [];
  final List<TextEditingController> _diasExecutadosControllers = [];
  final List<TextEditingController> _tipoControllers = [];
  final List<TextEditingController> _domControllers = [];
  final List<DateTime?> _selectedDeadlineDates = [];
  final List<bool> _isCollapsedList = [];
  late String _userAccessLevel = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosSalvosDoFirestore();
    _fetchUserData();

    Map<String, dynamic>? obraData =
        widget.obra.data() as Map<String, dynamic>?;

    if (obraData != null) {
      List<dynamic>? prazosAditados = obraData['prazos_aditados'];
      if (prazosAditados != null) {
        for (int i = 0; i < prazosAditados.length; i++) {
          Map<String, dynamic> prazoAditado = prazosAditados[i];

          _extendedDeadlineControllers.add(
            TextEditingController(
              text: prazoAditado['dias_paralisados'].toString(),
            ),
          );
          _contractorNameControllers.add(
            TextEditingController(
              text: prazoAditado['nome_contratada'].toString(),
            ),
          );
          _dataAssinaturaControllers.add(
            TextEditingController(
              text: prazoAditado['data_assinatura'].toString(),
            ),
          );
          _dataPublicacaoControllers.add(
            TextEditingController(
              text: prazoAditado['data_publicacao'].toString(),
            ),
          );
          _acrescimoControllers.add(
            TextEditingController(
              text: prazoAditado['acrescimo'].toString(),
            ),
          );
          _supressaoControllers.add(
            TextEditingController(
              text: prazoAditado['supressao'].toString(),
            ),
          );
          _repercussaoControllers.add(
            TextEditingController(
              text: prazoAditado['repercussao'].toString(),
            ),
          );
          _diasVigenciaControllers.add(
            TextEditingController(
              text: prazoAditado['dias_vigencia'].toString(),
            ),
          );
          _diasExecutadosControllers.add(
            TextEditingController(
              text: prazoAditado['dias_executados'].toString(),
            ),
          );
          _tipoControllers.add(
            TextEditingController(
              text: prazoAditado['tipo'].toString(),
            ),
          );
          _domControllers.add(
            TextEditingController(
              text: prazoAditado['dom'].toString(),
            ),
          );
          _selectedDeadlineDates.add(
            DateFormat('MM-yyyy').parse(prazoAditado['data']),
          );
          _isCollapsedList.add(true);
        }
      }
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

  Future<String?> _getContractorName() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('work')
          .doc(widget.obra.id)
          .get();
      return snapshot.data()?['contrato']?['contratada'];
    } catch (e) {
      print('Erro ao buscar o nome da contratada: $e');
      return null;
    }
  }

  void _carregarDadosSalvosDoFirestore() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('work')
          .doc(widget.obra.id)
          .get();

      Map<String, dynamic>? data = snapshot.data();

      if (data != null) {
        List<dynamic>? prazosAditados = data['prazos_aditados'];
        if (prazosAditados != null) {
          for (int i = 0; i < prazosAditados.length; i++) {
            Map<String, dynamic> prazoAditado = prazosAditados[i];
            if (i < _extendedDeadlineControllers.length) {
              _extendedDeadlineControllers[i].text =
                  prazoAditado['dias_paralisados'] ?? '';
              _contractorNameControllers[i].text =
                  prazoAditado['nome_contratada'] ?? '';
              _dataAssinaturaControllers[i].text =
                  prazoAditado['data_assinatura'] ?? '';
              _dataPublicacaoControllers[i].text =
                  prazoAditado['data_publicacao'] ?? '';
              _acrescimoControllers[i].text = prazoAditado['acrescimo'] ?? '';
              _supressaoControllers[i].text = prazoAditado['supressao'] ?? '';
              _repercussaoControllers[i].text =
                  prazoAditado['repercussao'] ?? '';
              _diasVigenciaControllers[i].text =
                  prazoAditado['dias_vigencia'] ?? '';
              _diasExecutadosControllers[i].text =
                  prazoAditado['dias_executados'] ?? '';
              _tipoControllers[i].text = prazoAditado['tipo'] ?? '';
              _domControllers[i].text = prazoAditado['dom'] ?? '';
              _selectedDeadlineDates[i] =
                  DateFormat('MM-yyyy').parse(prazoAditado['data'] ?? '');
            }
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar os dados do Firestore: $e');
    }
  }

  Widget _buildPrazoFields(int index) {
    return Column(
      children: [
        TextFormField(
          controller: _domControllers[index],
          decoration: const InputDecoration(labelText: 'Nº Dom'),
        ),
        GestureDetector(
          onTap: () async {
            String? selectedDate = await _selectDateComplete(context, index);
            if (selectedDate != null) {
              _dataAssinaturaControllers[index].text = selectedDate;
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Data de Assinatura',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: _dataAssinaturaControllers[index],
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            String? selectedDate = await _selectDateComplete(context, index);
            if (selectedDate != null) {
              _dataPublicacaoControllers[index].text = selectedDate;
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Data de Publicação',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: _dataPublicacaoControllers[index],
            ),
          ),
        ),
        TextFormField(
          controller: _diasVigenciaControllers[index],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Dias de Vigência'),
        ),
        TextFormField(
          controller: _diasExecutadosControllers[index],
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Dias Executados'),
        ),
      ],
    );
  }

  Widget _buildValorFields(int index) {
    return Column(
      children: [
        TextFormField(
          controller: _domControllers[index],
          decoration: const InputDecoration(labelText: 'Nº Dom'),
        ),
        GestureDetector(
          onTap: () async {
            String? selectedDate = await _selectDateComplete(context, index);
            if (selectedDate != null) {
              _dataAssinaturaControllers[index].text = selectedDate;
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Data de Assinatura',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: _dataAssinaturaControllers[index],
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            String? selectedDate = await _selectDateComplete(context, index);
            if (selectedDate != null) {
              _dataPublicacaoControllers[index].text = selectedDate;
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Data de Publicação',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: _dataPublicacaoControllers[index],
            ),
          ),
        ),
        TextFormField(
          controller: _acrescimoControllers[index],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[,]')),
          ],
          decoration: InputDecoration(
            labelText: 'Acréscimo',
            suffixIcon: Tooltip(
                message: 'Formato correto: 00.0',
                textStyle: const TextStyle(color: Colors.white),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(left: 8),
                child: const Icon(Icons.help)),
          ),
        ),
        TextFormField(
          controller: _supressaoControllers[index],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[,]')),
          ],
          decoration: InputDecoration(
              labelText: 'Supressão',
              suffixIcon: Tooltip(
                  message: 'Formato correto: 00.0',
                  textStyle: const TextStyle(color: Colors.white),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(left: 8),
                  child: const Icon(Icons.help))),
        ),
        TextFormField(
          controller: _repercussaoControllers[index],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[,]')),
          ],
          decoration: InputDecoration(
              labelText: 'Repercussão',
              suffixIcon: Tooltip(
                  message: 'Formato correto: 00.0',
                  textStyle: const TextStyle(color: Colors.white),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(left: 8),
                  child: const Icon(Icons.help))),
        ),
      ],
    );
  }

  Widget _buildParalisacaoFields(int index) {
    return Column(
      children: [
        TextFormField(
          controller: _extendedDeadlineControllers[index],
          decoration: const InputDecoration(labelText: 'Dias Paralisados'),
        ),
      ],
    );
  }

  Widget _buildTipoFields(int index) {
    String selectedType = _tipoControllers[index].text;
    switch (selectedType) {
      case 'Prazo':
        return _buildPrazoFields(index);
      case 'Valor':
        return _buildValorFields(index);
      case 'Paralização':
        return _buildParalisacaoFields(index);
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aditivos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Obra Selecionada: ${widget.obra['nome']} - ${widget.obra['num_contrato']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Column(
                children: List.generate(
                  _extendedDeadlineControllers.length,
                  (index) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.grey[200],
                    ),
                    padding: const EdgeInsets.only(left: 13.0, right: 13),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('${index + 1}º Tempo aditivo'),
                            const Spacer(),
                            _buildCollapseButton(index),
                          ],
                        ),
                        if (!_isCollapsedList[index]) ...[
                          DropdownButtonFormField<String>(
                            value: _tipoControllers[index].text.isNotEmpty
                                ? _tipoControllers[index].text
                                : null,
                            items: [
                              null,
                              "Valor",
                              "Prazo",
                              "Paralização",
                            ].map((String? value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Text(
                                    value ?? "Selecione um item",
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _clearFields(index);
                                _tipoControllers[index].text = newValue ?? '';
                              });
                            },
                            decoration:
                                const InputDecoration(labelText: 'Tipo'),
                          ),
                          _buildTipoFields(index),
                          const SizedBox(
                            height: 10,
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                child: ElevatedButton(
                  onPressed: () {
                    _salvarDados();
                  },
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
        onPressed: _adicionarPrazoAditado,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCollapseButton(int index) {
    return Row(
      children: [
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
    );
  }

  void _adicionarPrazoAditado() async {
    String? contractorName = await _getContractorName();
    setState(() {
      _extendedDeadlineControllers.add(TextEditingController());
      _contractorNameControllers
          .add(TextEditingController(text: contractorName ?? ''));
      _dataAssinaturaControllers.add(TextEditingController());
      _dataPublicacaoControllers.add(TextEditingController());
      _acrescimoControllers.add(TextEditingController());
      _supressaoControllers.add(TextEditingController());
      _repercussaoControllers.add(TextEditingController());
      _diasVigenciaControllers.add(TextEditingController());
      _diasExecutadosControllers.add(TextEditingController());
      _tipoControllers.add(TextEditingController());
      _domControllers.add(TextEditingController());
      _selectedDeadlineDates.add(null);
      _isCollapsedList.add(false);
    });
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
                _removerPrazoAditado(index);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  void _removerPrazoAditado(int index) async {
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

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('work')
          .doc(widget.obra.id)
          .get();

      Map<String, dynamic>? data = snapshot.data();

      if (data != null) {
        List<dynamic>? prazosAditados = data['prazos_aditados'];
        if (prazosAditados != null && prazosAditados.length > index) {
          prazosAditados.removeAt(index);
          await FirebaseFirestore.instance
              .collection('work')
              .doc(widget.obra.id)
              .update({'prazos_aditados': prazosAditados});
        }
      }

      setState(() {
        _extendedDeadlineControllers.removeAt(index);
        _contractorNameControllers.removeAt(index);
        _dataAssinaturaControllers.removeAt(index);
        _dataPublicacaoControllers.removeAt(index);
        _acrescimoControllers.removeAt(index);
        _supressaoControllers.removeAt(index);
        _repercussaoControllers.removeAt(index);
        _diasVigenciaControllers.removeAt(index);
        _diasExecutadosControllers.removeAt(index);
        _tipoControllers.removeAt(index);
        _domControllers.removeAt(index);
        _selectedDeadlineDates.removeAt(index);
        _isCollapsedList.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Item removido com sucesso!'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ));

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const UserHome(),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao remover o item. $e'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<String?> _selectDateComplete(BuildContext context, int index) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadlineDates[index] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDeadlineDates[index] = pickedDate;
      });
      return DateFormat('dd/MM/yyyy').format(pickedDate);
    }
    return null;
  }

  void _salvarDados() async {
    List<String> permittedLevels = [
      'MASTER',
      'GESTOR',
    ];

    if (!permittedLevels.contains(_userAccessLevel)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Usuário sem permissão para salvar os dados de prazos.',
            style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
      return;
    }

    List<Map<String, dynamic>> prazosAditados = [];

    for (int i = 0; i < _extendedDeadlineControllers.length; i++) {
      String diasParalisados = _extendedDeadlineControllers[i].text.trim();
      String contratada = _contractorNameControllers[i].text.trim();
      String dataAssinatura = _dataAssinaturaControllers[i].text.trim();
      String dataPublicacao = _dataPublicacaoControllers[i].text.trim();
      String acrescimo = _acrescimoControllers[i].text.trim();
      String supressao = _supressaoControllers[i].text.trim();
      String repercussao = _repercussaoControllers[i].text.trim();
      String diasVigencia = _diasVigenciaControllers[i].text.trim();
      String diasExecutados = _diasExecutadosControllers[i].text.trim();
      String tipo = _tipoControllers[i].text.trim();
      String dom = _domControllers[i].text.trim();

      String data = DateFormat('MM-yyyy').format(DateTime.now());

      diasParalisados = diasParalisados.isNotEmpty ? diasParalisados : '0';
      acrescimo = acrescimo.isNotEmpty ? acrescimo : '0';
      supressao = supressao.isNotEmpty ? supressao : '0';
      repercussao = repercussao.isNotEmpty ? repercussao : '0';
      diasVigencia = diasVigencia.isNotEmpty ? diasVigencia : '0';
      diasExecutados = diasExecutados.isNotEmpty ? diasExecutados : '0';

      prazosAditados.add({
        'nome_contratada': contratada,
        'dias_paralisados': diasParalisados,
        'data': data,
        'data_assinatura': dataAssinatura,
        'data_publicacao': dataPublicacao,
        'dom': dom,
        'acrescimo': acrescimo,
        'supressao': supressao,
        'repercussao': repercussao,
        'dias_vigencia': diasVigencia,
        'dias_executados': diasExecutados,
        'tipo': tipo,
      });
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (context) => const UserHome(),
    ));

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Dados de aditivos salvos com sucesso.',
          style: TextStyle(color: Colors.white)),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.green,
    ));

    await FirebaseFirestore.instance
        .collection('work')
        .doc(widget.obra.id)
        .update({
      'prazos_aditados': prazosAditados,
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Dados salvos com sucesso!'),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ));
  }

  void _clearFields(int index) {
    _extendedDeadlineControllers[index].clear();
    _contractorNameControllers[index].clear();
    _dataAssinaturaControllers[index].clear();
    _dataPublicacaoControllers[index].clear();
    _acrescimoControllers[index].clear();
    _supressaoControllers[index].clear();
    _repercussaoControllers[index].clear();
    _diasVigenciaControllers[index].clear();
    _diasExecutadosControllers[index].clear();
    _domControllers[index].clear();
    _selectedDeadlineDates[index] = null;
  }

  @override
  void dispose() {
    for (var controller in _extendedDeadlineControllers) {
      controller.dispose();
    }
    for (var controller in _contractorNameControllers) {
      controller.dispose();
    }
    for (var controller in _dataAssinaturaControllers) {
      controller.dispose();
    }
    for (var controller in _dataPublicacaoControllers) {
      controller.dispose();
    }
    for (var controller in _acrescimoControllers) {
      controller.dispose();
    }
    for (var controller in _supressaoControllers) {
      controller.dispose();
    }
    for (var controller in _repercussaoControllers) {
      controller.dispose();
    }
    for (var controller in _diasVigenciaControllers) {
      controller.dispose();
    }
    for (var controller in _diasExecutadosControllers) {
      controller.dispose();
    }
    for (var controller in _tipoControllers) {
      controller.dispose();
    }
    for (var controller in _domControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
