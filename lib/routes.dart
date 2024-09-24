import 'package:flutter/cupertino.dart';
import 'pages/middleware.dart';
import 'pages/sign_up.dart';

class Routes {
  static Map<String, Widget Function(BuildContext context)> routes =
      <String, WidgetBuilder>{
    '/checagem': (context) => const ChecagemPage(),
    '/cadastro': (context) => const SignUpScreen(),
  };

  static String initialRoute = '/checagem';
}
