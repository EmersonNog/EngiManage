import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sobral_app/panel/panel_social/form_daily_production.dart';
import 'package:sobral_app/panel/panel_social/form_social_registration.dart';
import '../../webview/webview_container.dart';

class Social extends StatefulWidget {
  final QueryDocumentSnapshot obra;
  final String screenId;
  const Social({Key? key, required this.obra, required this.screenId})
      : super(key: key);

  @override
  State<Social> createState() => _SocialState();
}

class _SocialState extends State<Social> {
  void _showSnackbar(BuildContext context) {
    final snackBar = SnackBar(
      backgroundColor: Colors.red,
      content: const Text("O link para o Acervo Técnico está indisponível."),
      action: SnackBarAction(
        label: 'Fechar',
        textColor: Colors.white,
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Social",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Transform.translate(
              offset: const Offset(0, 20),
              child: Lottie.asset(
                'assets/social.json',
                width: 240,
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DailyProduction(
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
                    child: const Text('Produção Diária'),
                  ),
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
                            builder: (context) => SocialRegistration(
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
                    child: const Text('Cadastro Social'),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                if (widget.obra['contrato']['tipo_obra'] ==
                    "SISTEMA DE ESGOTAMENTO SANITÁRIO") ...[
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: ElevatedButton(
                      onPressed: () {
                        final String? acervoUrl =
                            widget.obra['contrato']['acervo_social'] as String?;
                        if (acervoUrl == null || acervoUrl.isEmpty) {
                          _showSnackbar(context);
                        } else {
                          Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                            builder: (context) => WebViewContainer(
                              url: acervoUrl,
                            ),
                          ));
                        }
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
                      child: const Text('Acervo Técnico'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
