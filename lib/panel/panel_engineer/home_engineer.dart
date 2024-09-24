import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sobral_app/panel/panel_engineer/form_quantitative.dart';
import 'form_services.dart';

class Engineer extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  final String screenId;
  const Engineer({Key? key, required this.obra, required this.screenId})
      : super(key: key);

  @override
  State<Engineer> createState() => _EngineerState();
}

class _EngineerState extends State<Engineer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Engenharia",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            children: [
              Lottie.asset('assets/engineer.json', width: 120, height: 120),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Services(
                                obra: widget.obra,
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
                  child: const Text('Serviços'),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              if (widget.obra['contrato']['tipo_obra'] !=
                  "CONSTRUÇÃO CIVIL") ...[
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Quantitative(
                                  obra: widget.obra,
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
                    child: const Text('Quantitativo'),
                  ),
                ),
              ],
              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ));
  }
}
