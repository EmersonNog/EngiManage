import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sobral_app/webview/webview_container.dart';
import 'user_home.dart';

class Annex extends StatefulWidget {
  const Annex({super.key});

  @override
  State<Annex> createState() => _AnnexState();
}

class _AnnexState extends State<Annex> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 70, 96, 209),
        title: const Text(
          "Relatórios",
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const UserHome(),
              ),
            );
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: content(),
    );
  }

  Widget content() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Lottie.asset('assets/report.json', height: 280),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const WebViewContainer(
                      url:
                          'https://1drv.ms/f/s!Ajrs6sxeRNE_jrl5RS16x9FHQsNy7A?e=T3jEpS',
                    ),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Relatórios Semanais",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const WebViewContainer(
                      url:
                          'https://1drv.ms/f/s!Ajrs6sxeRNE_jrl4aVonamZfpUe8Uw?e=TchbUN',
                    ),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Relatórios Mensais",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
