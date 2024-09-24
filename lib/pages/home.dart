// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'work.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String searchText = '';
  final TextEditingController _searchController = TextEditingController();

  String? _userAccessLevel;
  List<String> _selectedStatuses = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final items = [
      'Concluída',
      'Paralisada',
      'Em Andamento',
    ].map((status) => MultiSelectItem<String>(status, status)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Obras - PRODESOL',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 12, right: 12, bottom: 9, top: 5),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Buscar por nome da obra',
                labelStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            searchText = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: MultiSelectDialogField(
              items: items,
              title: const Text("Status da obra"),
              selectedColor: Colors.blue,
              backgroundColor: Colors.white,
              dialogHeight: 200,
              searchable: true,
              searchHint: "Buscar",
              confirmText: const Text(
                "OK",
                style: TextStyle(color: Colors.blue),
              ),
              cancelText: const Text(
                "CANCELAR",
                style: TextStyle(color: Colors.blue),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey,
                ),
              ),
              buttonIcon: const Icon(
                Icons.filter_list,
                color: Colors.blue,
              ),
              buttonText: const Text(
                "Filtrar por status da obra",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              chipDisplay: MultiSelectChipDisplay(
                textStyle: const TextStyle(fontSize: 12),
              ),
              onConfirm: (results) {
                setState(() {
                  _selectedStatuses = results.cast<String>();
                });
              },
            ),
          ),
          const Divider(indent: 35, endIndent: 35),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('work').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (snapshot.data?.docs.isEmpty ?? true) {
                  return Center(
                    child: Lottie.asset('assets/not_found.json', height: 280),
                  );
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var obra = doc.data() as Map<String, dynamic>;
                  var nome = obra['nome'].toString().toLowerCase();
                  var statusObra = obra['contrato']['status_obra'].toString();

                  bool matchesSearchText =
                      nome.contains(searchText.toLowerCase());
                  bool matchesStatus = _selectedStatuses.isEmpty ||
                      _selectedStatuses.contains(statusObra);

                  return matchesSearchText && matchesStatus;
                }).toList();

                const statusPrioridade = {
                  'Em Andamento': 1,
                  'Paralisada': 2,
                  'Concluída': 3,
                };

                filteredDocs.sort(
                  (a, b) {
                    var statusA = (a.data() as Map<String, dynamic>)['contrato']
                        ['status_obra'] as String;
                    var statusB = (b.data() as Map<String, dynamic>)['contrato']
                        ['status_obra'] as String;

                    int prioridadeA = statusPrioridade[statusA] ?? 999;
                    int prioridadeB = statusPrioridade[statusB] ?? 999;

                    return prioridadeA.compareTo(prioridadeB);
                  },
                );

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var obra = filteredDocs[index];
                    var nome = obra['nome'];
                    var numberContrato = obra['num_contrato'];
                    var statusObra = obra['contrato']['status_obra'];

                    final data = obra.data() as Map<String, dynamic>?;

                    double valorInicialContrato =
                        obra['contrato']['valor_inicial_contrato'] as double;
                    double valorPago = 0;
                    double totalRepercussoes = 0;
                    if (data != null && data.containsKey('prazos_aditados')) {
                      for (var prazo
                          in data['prazos_aditados'] as List<dynamic>) {
                        if (prazo.containsKey('repercussao')) {
                          totalRepercussoes += double.tryParse(
                                  prazo['repercussao'].toString()) ??
                              0;
                        }
                      }
                    }

                    if (data != null && data.containsKey('pagamentos')) {
                      for (var payment in data['pagamentos'] as List<dynamic>) {
                        valorPago += double.parse(payment['valor'] as String);
                      }
                    } else {
                      valorPago = 0;
                    }
                    double valorAtual =
                        valorInicialContrato + totalRepercussoes;
                    double porcentagemConcluida = valorPago / valorAtual;
                    porcentagemConcluida =
                        porcentagemConcluida.clamp(0.0, 1.0) * 100;
                    String formattedPorcentagem =
                        NumberFormat('0.00').format(porcentagemConcluida);

                    return Card(
                      elevation: 2,
                      color: statusObra == 'Concluída'
                          ? Colors.green[100]
                          : statusObra == 'Paralisada'
                              ? Colors.red[100]
                              : statusObra == 'Em Andamento'
                                  ? Colors.yellow[100]
                                  : Colors.grey[50],
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          'Obra: $nome',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contrato: $numberContrato'),
                            Text('Medição: $formattedPorcentagem%'),
                          ],
                        ),
                        leading: const Icon(Icons.engineering),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ObraDetalhesScreen(obra: obra),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: Colors.blue[300],
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    TextEditingController nomeController =
                                        TextEditingController(text: nome);
                                    TextEditingController
                                        numberContratoController =
                                        TextEditingController(
                                            text: numberContrato);

                                    return AlertDialog(
                                      title: const Text('Editar Obra'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: nomeController,
                                            decoration: const InputDecoration(
                                                labelText: 'Novo Nome da Obra'),
                                          ),
                                          TextField(
                                            controller:
                                                numberContratoController,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'Novo Número do Contrato'),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Fecha o diálogo
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            if (_userAccessLevel == 'MASTER' ||
                                                _userAccessLevel == 'GESTOR') {
                                              await FirebaseFirestore.instance
                                                  .collection('work')
                                                  .doc(obra.id)
                                                  .update({
                                                'nome': nomeController.text,
                                                'num_contrato':
                                                    numberContratoController
                                                        .text,
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Obra editada com sucesso.'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Você não tem permissão para editar esta obra.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Salvar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red[300],
                              ),
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Confirmar Exclusão'),
                                      content: const Text(
                                          'Você tem certeza de que deseja excluir esta obra?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            if (_userAccessLevel == 'MASTER') {
                                              await FirebaseFirestore.instance
                                                  .collection('work')
                                                  .doc(obra.id)
                                                  .delete();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Obra excluída com sucesso.'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Você não tem permissão para excluir esta obra.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Excluir'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
