// ignore_for_file: avoid_print, library_private_types_in_public_api, constant_identifier_names

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sobral_app/panel/panel_data_crono_pay/data.dart';
import 'package:sobral_app/panel/panel_overview/form_overview/form_contract.dart';
import 'package:sobral_app/panel/panel_overview/form_overview/form_crono.dart';
import 'package:sobral_app/panel/panel_overview/form_overview/form_payment.dart';
import 'package:sobral_app/panel/panel_overview/form_overview/form_readjustment.dart';
import 'package:sobral_app/panel/panel_overview/form_overview/form_work.dart';

class DashboardScreen extends StatefulWidget {
  final QueryDocumentSnapshot obra;

  const DashboardScreen({
    Key? key,
    required this.obra,
  }) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double valorInicialContrato = 0;
  double valorPago = 0;
  double valorFaltante = 0;
  String? nomeObra;
  String? numeroContrato;
  String? dataInicioReal;
  String? prazoInicial;
  int totalDiasParalisados = 0;
  int totalDiasExecucao = 0;
  late DateTime dataFimPrevisto;
  double somaRepercussoes = 0;
  double valorAtual = 0;
  bool aditivosCarregados = false;
  late String _userAccessLevel = '';

  @override
  void initState() {
    super.initState();
    _fetchWorkDetails();
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

  Future<void> _fetchWorkDetails() async {
    try {
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .get();

      final obraData = snapshot.data() as Map<String, dynamic>;
      final List<dynamic>? prazosAditados = obraData['prazos_aditados'];
      final List<dynamic>? pagamentos = obraData['pagamentos'];
      final contrato = obraData['contrato'] as Map<String, dynamic>?;

      double totalPago = 0;
      if (pagamentos != null) {
        for (var pagamento in pagamentos) {
          if (pagamento.containsKey('valor')) {
            String valorStr =
                pagamento['valor'].toString().replaceAll(',', '').trim();
            totalPago += double.tryParse(valorStr) ?? 0;
          }
        }
      }

      double totalRepercussoes = 0;
      if (prazosAditados != null) {
        for (var prazo in prazosAditados) {
          if (prazo.containsKey('repercussao')) {
            double repercussao = prazo['repercussao'] is double
                ? prazo['repercussao']
                : prazo['repercussao'] is int
                    ? (prazo['repercussao'] as int).toDouble()
                    : double.tryParse(prazo['repercussao'].toString()) ?? 0;
            totalRepercussoes += repercussao;
          }
        }
      }

      setState(() {
        aditivosCarregados = true;
        nomeObra = obraData['nome'];
        numeroContrato = obraData['num_contrato'];
        dataInicioReal = contrato?['data_inicio_real'];
        prazoInicial = contrato?['prazo_inicial_execucao'];
        valorInicialContrato =
            contrato != null && contrato.containsKey('valor_inicial_contrato')
                ? double.tryParse(contrato['valor_inicial_contrato']
                        .toString()
                        .replaceAll(',', '')
                        .trim()) ??
                    0
                : 0;

        totalDiasParalisados = 0;
        totalDiasExecucao = 0;
        somaRepercussoes = totalRepercussoes;
        valorAtual = valorInicialContrato + somaRepercussoes;
        valorPago = totalPago;
        valorFaltante = valorAtual - valorPago;
        if (valorFaltante < 0) valorFaltante = 0;

        if (prazosAditados != null) {
          for (var prazo in prazosAditados) {
            if (prazo.containsKey('dias_paralisados')) {
              String diasParalisadosStr = prazo['dias_paralisados']
                  .toString()
                  .replaceAll(',', '')
                  .trim();
              totalDiasParalisados += int.tryParse(diasParalisadosStr) ?? 0;
            }
            if (prazo.containsKey('dias_executados')) {
              String diasExecutadosStr = prazo['dias_executados']
                  .toString()
                  .replaceAll(',', '')
                  .trim();
              totalDiasExecucao += int.tryParse(diasExecutadosStr) ?? 0;
            }
          }
        }

        final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
        final startDate = dateFormat.parse(dataInicioReal!);
        dataFimPrevisto = startDate.add(Duration(
            days: totalDiasExecucao +
                int.parse(prazoInicial!) +
                totalDiasParalisados -
                1));
      });
    } catch (e) {
      print('Erro ao buscar detalhes da obra: $e');
      _showErrorDialog('Erro ao buscar detalhes da obra');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                'Erro',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final valorFormatado = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(valorInicialContrato);

    final valorPagoFormatado = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(valorPago);

    final valorFaltanteFormatado = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(valorFaltante);

    final valorAditFormatado = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(somaRepercussoes);

    final valorAtualFormatado = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(valorAtual);
    final bool isPrefeito = _userAccessLevel == 'PREFEITO';
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          nomeObra ?? 'Carregando...',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text("Visão Geral",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            _buildValueRow(valorPagoFormatado, valorFaltanteFormatado),
            const SizedBox(height: 10),
            _buildInfoRow(
                valorFormatado, valorAditFormatado, valorAtualFormatado),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text("Catálogo",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Center(
                child: GridView.count(
                  physics: const ScrollPhysics(
                      parent: NeverScrollableScrollPhysics()),
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  children: [
                    _buildTile(
                      title: 'Prazos Aditados',
                      icon: FontAwesomeIcons.calendarCheck,
                      color: const Color.fromARGB(255, 47, 33, 243),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FormWorkScreen(obra: widget.obra),
                          ),
                        );
                      },
                    ),
                    _buildTile(
                      title: 'Dados do Contrato',
                      icon: FontAwesomeIcons.fileContract,
                      color: Colors.brown,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ContractFormScreen(obra: widget.obra),
                          ),
                        );
                      },
                    ),
                    if (!isPrefeito)
                      _buildTile(
                        title: 'Pagamentos',
                        icon: FontAwesomeIcons.moneyBill1Wave,
                        color: const Color.fromARGB(255, 54, 169, 58),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PaymentDataScreen(obra: widget.obra),
                            ),
                          );
                        },
                      ),
                    _buildTile(
                      title: 'Reajuste',
                      icon: FontAwesomeIcons.moneyBillTrendUp,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  Readjustment(obra: widget.obra)),
                        );
                      },
                    ),
                    if (!isPrefeito)
                      _buildTile(
                        title: 'Cronograma',
                        icon: FontAwesomeIcons.calendarDays,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Crono(obra: widget.obra)),
                          );
                        },
                      ),
                    _buildTile(
                      title: 'Histórico',
                      icon: FontAwesomeIcons.clock,
                      color: Colors.red.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DataWork(obra: widget.obra),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 50,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String valorFormatado, String valorAditFormatado,
      String valorAtualFormatado) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildInfoCard(
          title: "Aditivo de prazo",
          content: [
            'Início real: ${dataInicioReal ?? 0}',
            'Prazo inicial: ${prazoInicial ?? 0}',
            'Dias aditados: $totalDiasExecucao',
            'Dias paralisados: $totalDiasParalisados',
            'Fim previsto: ${aditivosCarregados ? DateFormat('dd/MM/yyyy').format(dataFimPrevisto) : 'Carregando'}',
          ],
        ),
        const SizedBox(width: 10),
        _buildInfoCard(
          title: "Aditivo de valor",
          content: [
            'Valor contratual: $valorFormatado',
            'Valor aditivado: $valorAditFormatado',
            'Valor atual: $valorAtualFormatado',
          ],
        ),
      ],
    );
  }

  Widget _buildValueRow(
      String valorPagoFormatado, String valorFaltanteFormatado) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildValueCard(
          icon: FontAwesomeIcons.solidMoneyBill1,
          color: Colors.blue,
          label: "Valor Medido",
          value: valorPagoFormatado,
        ),
        const SizedBox(width: 10),
        _buildValueCard(
          icon: FontAwesomeIcons.solidMoneyBill1,
          color: Colors.red,
          label: "Saldo da Obra",
          value: valorFaltanteFormatado,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<String> content,
  }) {
    return Flexible(
      child: Material(
        elevation: 4,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.467,
          height: MediaQuery.of(context).size.height * 0.200,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                ...content.map((text) => Text(
                      text,
                      style: const TextStyle(fontSize: 14),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Flexible(
      child: Tooltip(
        message: value,
        child: Material(
          elevation: 4,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.467,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FaIcon(
                    icon,
                    color: color,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  AutoSizeText(
                    "$label \n$value",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 124, 124, 124),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    minFontSize: 18,
                    maxFontSize: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
