// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sobral_app/pages/user_home.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContractFormScreen extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  const ContractFormScreen({Key? key, required this.obra}) : super(key: key);
  @override
  _ContractFormScreenState createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _userAccessLevel = '';
  late String _selectedTipoObra = '';
  late String _selectedStatusObra = '';
  final List<String> _tipoObraOptions = [
    'SISTEMA DE ESGOTAMENTO SANITÁRIO',
    'DRENAGEM PLUVIAL',
    'CONSTRUÇÃO CIVIL',
  ];
  final List<String> _statusObraOptions = [
    'Concluída',
    'Em Andamento',
    'Paralisada',
  ];

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

  @override
  void initState() {
    super.initState();
    _preencherCampos();
    _fetchUserData();
  }

  void _preencherCampos() {
    final Map<String, dynamic>? obraData =
        widget.obra.data() as Map<String, dynamic>?;
    if (obraData != null && obraData.containsKey('contrato')) {
      final contrato = obraData['contrato'] as Map<String, dynamic>;
      setState(() {
        _selectedTipoObra = contrato['tipo_obra'] ?? '';
        _selectedStatusObra = contrato['status_obra'] ?? '';
        contratadaController.text = contrato['contratada'] ?? '';
        acervoSocialController.text = contrato['acervo_social'] ?? '';
        dataAssinaturaController.text = contrato['data_assinatura'] ?? '';
        dataInicioRealController.text = contrato['data_inicio_real'] ?? '';
        ordemServicoController.text = contrato['ordem_servico'] ?? '';
        objetoContratoController.text = contrato['objeto_contrato'] ?? '';
        prazoInicialExecucaoController.text =
            contrato['prazo_inicial_execucao'] ?? '';
        dataTerminoInicialController.text =
            contrato['data_termino_inicial'] ?? '';
        valorInicialContratoController.text =
            contrato['valor_inicial_contrato'].toString();
        fiscalContratoController.text = contrato['fiscal_contrato'] ?? '';
        fiscalConsorcioController.text = contrato['fiscal_consorcio'] ?? '';
      });
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_userAccessLevel == 'MASTER' || _userAccessLevel == 'GESTOR') {
        final obraId = widget.obra.id;

        Map<String, dynamic> contratoData = {
          'tipo_obra': _selectedTipoObra,
          'status_obra': _selectedStatusObra,
          'contratada': contratadaController.text,
          'acervo_social': acervoSocialController.text,
          'data_assinatura': dataAssinaturaController.text,
          'data_inicio_real': dataInicioRealController.text,
          'ordem_servico': ordemServicoController.text,
          'objeto_contrato': objetoContratoController.text,
          'prazo_inicial_execucao': prazoInicialExecucaoController.text,
          'data_termino_inicial': dataTerminoInicialController.text,
          'valor_inicial_contrato':
              double.parse(valorInicialContratoController.text),
          'fiscal_contrato': fiscalContratoController.text,
          'fiscal_consorcio': fiscalConsorcioController.text
        };

        await FirebaseFirestore.instance.collection('work').doc(obraId).update({
          'contrato': contratoData,
        });

        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const UserHome(),
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Formulário enviado com sucesso!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Você não tem permissão para salvar este formulário.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dados de Contrato',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Obra Selecionada: ${widget.obra['nome']} - ${widget.obra['num_contrato']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Tipo: ${widget.obra['contrato']['tipo_obra']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _selectedTipoObra.isNotEmpty ? _selectedTipoObra : null,
                items: _tipoObraOptions.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: 'Tipo de Obra'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTipoObra = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione o tipo de obra';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value:
                    _selectedStatusObra.isNotEmpty ? _selectedStatusObra : null,
                items: _statusObraOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: 'Status da Obra'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatusObra = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione o status da obra';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: contratadaController,
                decoration: const InputDecoration(labelText: 'Contratada'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a contratada';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              if (_selectedTipoObra == 'SISTEMA DE ESGOTAMENTO SANITÁRIO')
                TextFormField(
                  controller: acervoSocialController,
                  decoration:
                      const InputDecoration(labelText: 'Link do Acervo Social'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o link';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 10),
              TextFormField(
                controller: dataAssinaturaController,
                decoration: const InputDecoration(
                  labelText: 'Data de Assinatura',
                  hintText: 'dd/mm/aaaa',
                ),
                onTap: () {
                  _selectDate(context, dataAssinaturaController);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a data de assinatura';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: dataInicioRealController,
                decoration: const InputDecoration(
                  labelText: 'Data de Início Real',
                  hintText: 'dd/mm/aaaa',
                ),
                onTap: () {
                  _selectDate(context, dataInicioRealController);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a data de início real';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: ordemServicoController,
                decoration:
                    const InputDecoration(labelText: 'Ordem de Serviço'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a ordem de serviço';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: objetoContratoController,
                decoration:
                    const InputDecoration(labelText: 'Objeto do Contrato'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o objeto do contrato';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: prazoInicialExecucaoController,
                decoration: const InputDecoration(
                    labelText: 'Prazo Inicial de Execução'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o prazo inicial de execução';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: dataTerminoInicialController,
                decoration: const InputDecoration(
                  labelText: 'Data de Término Inicial',
                  hintText: 'dd/mm/aaaa',
                ),
                onTap: () {
                  _selectDate(context, dataTerminoInicialController);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a data de término inicial';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: valorInicialContratoController,
                decoration: const InputDecoration(
                  labelText: 'Valor Inicial do Contrato',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o valor inicial do contrato';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: fiscalContratoController,
                decoration:
                    const InputDecoration(labelText: 'Fiscal do Contrato'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o fiscal do contrato';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: fiscalConsorcioController,
                decoration:
                    const InputDecoration(labelText: 'Fiscal do Consórcio'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o fiscal do consórcio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
