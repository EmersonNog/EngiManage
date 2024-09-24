// ignore_for_file: library_private_types_in_public_api
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DataWork extends StatefulWidget {
  final QueryDocumentSnapshot obra;

  const DataWork({Key? key, required this.obra}) : super(key: key);

  @override
  _DataWorkState createState() => _DataWorkState();
}

class _DataWorkState extends State<DataWork> {
  int selectedYear = DateTime.now().year;
  List<int> availableYears = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableYears();
  }

  String formatCurrency(double value) {
    String stringValue = value.toString().replaceAll('.', ',');

    List<String> parts = stringValue.split(',');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? ',${parts[1]}' : '';

    String formattedValue = '';
    int counter = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      counter++;
      formattedValue = integerPart[i] + formattedValue;
      if (counter == 3 && i != 0) {
        formattedValue = '.$formattedValue';
        counter = 0;
      }
    }

    return formattedValue + decimalPart;
  }

  void _fetchAvailableYears() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('work')
        .doc(widget.obra.id)
        .get();

    List<dynamic>? crono = snapshot.data()?['cronograma'];
    List<dynamic>? payments = snapshot.data()?['pagamentos'];

    Set<int> yearsSet = {};

    if (crono != null) {
      for (var item in crono) {
        String date = item['data'];
        int year = int.parse(date.split('/')[1]);
        yearsSet.add(year);
      }
    }

    if (payments != null) {
      for (var item in payments) {
        String date = item['data'];
        int year = int.parse(date.split('/')[1]);
        yearsSet.add(year);
      }
    }

    setState(() {
      availableYears = yearsSet.toList()..sort();
      if (availableYears.isNotEmpty) {
        selectedYear = availableYears.first;
      }
    });
  }

  Widget _buildAlignedDetails(List<dynamic> crono, List<dynamic> payments) {
    Map<String, dynamic> cronoMap = {
      for (var item in crono) item['data']: item
    };
    Map<String, dynamic> paymentMap = {
      for (var item in payments) item['data']: item
    };

    Set<String> allDatesSet = {...cronoMap.keys, ...paymentMap.keys};
    List<String> allDates = allDatesSet.toList()..sort();

    allDates = allDates
        .where((date) => date.split('/')[1] == selectedYear.toString())
        .toList();
    allDates = allDates.reversed.toList();

    List<Widget> listItems = [];
    int index = 0;

    for (String date in allDates) {
      Map<String, dynamic>? cronoItem = cronoMap[date];
      Map<String, dynamic>? paymentItem = paymentMap[date];

      listItems.add(
        Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data: $date',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Cronograma ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Valor: ${formatCurrency(cronoItem != null ? double.tryParse(cronoItem['valor'].toString()) ?? 0.0 : 0.0)}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.payment,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Pagamento ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Valor: ${formatCurrency(paymentItem != null ? double.tryParse(paymentItem['valor'].toString()) ?? 0.0 : 0.0)}',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      index++;
    }

    return ListView(
      children: listItems,
    );
  }

  Widget _buildDetails() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('work')
          .doc(widget.obra.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const Center(
            child: Text("Ops!"),
          );
        }

        List<dynamic>? crono = snapshot.data?.data()?['cronograma'];
        List<dynamic>? payments = snapshot.data?.data()?['pagamentos'];

        crono ??= [];
        payments ??= [];

        if (crono.isEmpty && payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/not_found.json', width: 300, height: 300),
                const Text(
                  "Ops... Nenhuma informação encontrada!",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                )
              ],
            ),
          );
        }

        return _buildAlignedDetails(crono, payments);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Histórico - ${widget.obra['nome']}',
        ),
      ),
      body: Column(
        children: [
          if (availableYears.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: DropdownButton<int>(
                    value: selectedYear,
                    items: availableYears.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedYear = newValue!;
                      });
                    },
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    underline: Container(),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                ),
              ),
            ),
          Expanded(
            child: _buildDetails(),
          ),
        ],
      ),
    );
  }
}
