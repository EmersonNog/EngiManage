import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sobral_app/panel/panel_engineer/home_engineer.dart';
import 'package:sobral_app/panel/panel_environmental/home_environmental.dart';
import 'package:sobral_app/panel/panel_social/home_social.dart';
import '../panel/panel_overview/dashboard.dart';
import '../panel/panel_photo/album.dart';

class ObraDetalhesScreen extends StatelessWidget {
  final QueryDocumentSnapshot obra;

  const ObraDetalhesScreen({Key? key, required this.obra}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double valorInicialContrato =
        obra['contrato']['valor_inicial_contrato'] as double;

    double valorPago = 0;

    final data = obra.data() as Map<String, dynamic>?;

    if (data != null && data.containsKey('pagamentos')) {
      for (var payment in data['pagamentos'] as List<dynamic>) {
        valorPago += double.parse(payment['valor'] as String);
      }
    } else {
      valorPago = 0;
    }

    double totalRepercussoes = 0;
    if (data != null && data.containsKey('prazos_aditados')) {
      for (var prazo in data['prazos_aditados'] as List<dynamic>) {
        if (prazo.containsKey('repercussao')) {
          totalRepercussoes +=
              double.tryParse(prazo['repercussao'].toString()) ?? 0;
        }
      }
    }

    double valorAtual = valorInicialContrato + totalRepercussoes;
    double porcentagemConcluida = valorPago / valorAtual;
    porcentagemConcluida = porcentagemConcluida.clamp(0.0, 1.0) * 100;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 70, 96, 209),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              obra['nome'],
              style: const TextStyle(fontSize: 26, color: Colors.white),
            ),
            Text(
              obra['num_contrato'],
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Porcentagem da obra medida",
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 15,
              ),
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 7.0,
                percent: porcentagemConcluida / 100,
                center: Text("${porcentagemConcluida.toStringAsFixed(2)}%"),
                progressColor: Colors.black,
                animation: true,
                animationDuration: 1500,
                backgroundWidth: 12,
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DashboardScreen(
                                obra: obra,
                              )),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Visão Geral'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Engineer(
                                obra: obra,
                                screenId: "engenharia",
                              )),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Engenharia'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Environmental(
                                obra: obra,
                                screenId: "ambiental",
                              )),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Ambiental'),
                ),
              ),
              if (obra['contrato']['tipo_obra'] != "CONSTRUÇÃO CIVIL")
                Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Social(
                                      obra: obra,
                                      screenId: "social",
                                    )),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Social'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FotosScreen(
                                obra: obra,
                              )),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Fotos'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
