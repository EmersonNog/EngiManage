// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sobral_app/widgets/input_widget.dart';

class UserFormPage extends StatefulWidget {
  const UserFormPage({Key? key}) : super(key: key);

  @override
  _UserFormPageState createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  late String _userAccessLevel = '';
  TextEditingController nomeObraController = TextEditingController();
  TextEditingController numberContratoController = TextEditingController();

  TextEditingController contratadaController = TextEditingController();
  TextEditingController dataAssinaturaController = TextEditingController();
  TextEditingController dataInicioRealController = TextEditingController();
  TextEditingController ordemServicoController = TextEditingController();
  TextEditingController objetoContratoController = TextEditingController();
  TextEditingController prazoInicialExecucaoController =
      TextEditingController();
  TextEditingController dataTerminoInicialController = TextEditingController();
  TextEditingController valorInicialContratoController =
      TextEditingController();
  TextEditingController fiscalContratoController = TextEditingController();
  TextEditingController fiscalConsorcioController = TextEditingController();
  TextEditingController acervoSocialController = TextEditingController();
  late String _selectedStatusObra = '';
  final List<String> _statusObraOptions = [
    'Concluída',
    'Em Andamento',
    'Paralisada',
  ];

  late String _selectedTipoObra = '';
  final List<String> _tipoObraOptions = [
    'SISTEMA DE ESGOTAMENTO SANITÁRIO',
    'DRENAGEM PLUVIAL',
    'CONSTRUÇÃO CIVIL',
  ];

  @override
  void initState() {
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

  Future<void> _saveData(BuildContext context) async {
    String nomeObra = nomeObraController.text.trim();
    String nContrato = numberContratoController.text.trim();
    String valorContrato = valorInicialContratoController.text.trim();

    List<String> permittedLevels = [
      'MASTER',
      'GESTOR',
      'ENGENHARIA',
      'SOCIAL',
      'AMBIENTAL'
    ];

    List<TextEditingController> controllers = [
      nomeObraController,
      numberContratoController,
      contratadaController,
      dataAssinaturaController,
      dataInicioRealController,
      ordemServicoController,
      objetoContratoController,
      prazoInicialExecucaoController,
      dataTerminoInicialController,
      fiscalContratoController,
      fiscalConsorcioController,
    ];

    if (_selectedTipoObra == 'SISTEMA DE ESGOTAMENTO SANITÁRIO') {
      controllers.add(acervoSocialController);
    }

    if (!permittedLevels.contains(_userAccessLevel)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Usuário sem permissão para criar uma obra.',
            style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (controllers.any((controller) => controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double valorContratoDouble = double.tryParse(valorContrato) ?? 0;

    if (valorContratoDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um valor válido para o contrato.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance.collection('work').add({
          'nome': nomeObra,
          'num_contrato': nContrato,
          'contrato': {
            'contratada': contratadaController.text,
            'tipo_obra': _selectedTipoObra,
            'status_obra': _selectedStatusObra,
            'acervo_social':
                _selectedTipoObra == 'SISTEMA DE ESGOTAMENTO SANITÁRIO'
                    ? acervoSocialController.text
                    : null,
            'data_assinatura': dataAssinaturaController.text,
            'data_inicio_real': dataInicioRealController.text,
            'ordem_servico': ordemServicoController.text,
            'objeto_contrato': objetoContratoController.text,
            'prazo_inicial_execucao': prazoInicialExecucaoController.text,
            'data_termino_inicial': dataTerminoInicialController.text,
            'valor_inicial_contrato': valorContratoDouble,
            'fiscal_contrato': fiscalContratoController.text,
            'fiscal_consorcio': fiscalConsorcioController.text,
          },
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obra cadastrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        nomeObraController.clear();
        acervoSocialController.clear();
        numberContratoController.clear();
        contratadaController.clear();
        dataAssinaturaController.clear();
        dataInicioRealController.clear();
        ordemServicoController.clear();
        objetoContratoController.clear();
        prazoInicialExecucaoController.clear();
        dataTerminoInicialController.clear();
        valorInicialContratoController.clear();
        fiscalContratoController.clear();
        fiscalConsorcioController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário sem autorização!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar dados: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Nova obra",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 20,
              ),
              Center(
                child: Column(
                  children: [
                    CustomTextField(
                      hintText: "Nome da Obra*",
                      controller: nomeObraController,
                      keyboardType: TextInputType.text,
                      icon: Icons.construction,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedTipoObra.isNotEmpty
                          ? _selectedTipoObra
                          : null,
                      items: _tipoObraOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Obra*',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTipoObra = newValue!;
                        });
                      },
                      isExpanded: true,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedStatusObra.isNotEmpty
                          ? _selectedStatusObra
                          : null,
                      items: _statusObraOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                        labelText: 'Status da Obra*',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatusObra = newValue!;
                        });
                      },
                      isExpanded: true,
                    ),
                    if (_selectedTipoObra ==
                        'SISTEMA DE ESGOTAMENTO SANITÁRIO') ...[
                      const SizedBox(height: 20),
                      CustomTextField(
                        hintText: "Link do Acervo Social",
                        controller: acervoSocialController,
                        keyboardType: TextInputType.url,
                        icon: Icons.link,
                        inputWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                    ],
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Número do Contrato*",
                      controller: numberContratoController,
                      keyboardType: TextInputType.text,
                      icon: Icons.numbers,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Contratada",
                      controller: contratadaController,
                      keyboardType: TextInputType.text,
                      icon: Icons.business,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Data de Assinatura",
                      controller: dataAssinaturaController,
                      keyboardType: TextInputType.datetime,
                      icon: Icons.calendar_today,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                      onTap: () =>
                          _selectDate(context, dataAssinaturaController),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Data de Início Real",
                      controller: dataInicioRealController,
                      keyboardType: TextInputType.datetime,
                      icon: Icons.calendar_today,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                      onTap: () =>
                          _selectDate(context, dataInicioRealController),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Ordem de Serviço",
                      controller: ordemServicoController,
                      keyboardType: TextInputType.text,
                      icon: Icons.work,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Objeto do Contrato",
                      controller: objetoContratoController,
                      keyboardType: TextInputType.text,
                      icon: Icons.description,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Prazo Inicial de Execução",
                      controller: prazoInicialExecucaoController,
                      keyboardType: TextInputType.text,
                      icon: Icons.access_time,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Data de Término Inicial",
                      controller: dataTerminoInicialController,
                      keyboardType: TextInputType.datetime,
                      icon: Icons.calendar_today,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                      onTap: () =>
                          _selectDate(context, dataTerminoInicialController),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Valor Inicial do Contrato",
                      controller: valorInicialContratoController,
                      keyboardType: TextInputType.number,
                      icon: Icons.attach_money,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Fiscal do Contrato",
                      controller: fiscalContratoController,
                      keyboardType: TextInputType.text,
                      icon: Icons.person,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      hintText: "Fiscal do Consórcio",
                      controller: fiscalConsorcioController,
                      keyboardType: TextInputType.text,
                      icon: Icons.person,
                      inputWidth: MediaQuery.of(context).size.width * 0.9,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _saveData(context),
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
}
